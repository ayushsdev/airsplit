import Foundation
import Combine
import SimplyCoreAudio
import CoreAudio

final class AudioDeviceManager: ObservableObject {
    @Published var availableDevices: [BluetoothAudioDevice] = []
    @Published var masterVolume: Float = Constants.defaultMasterVolume
    @Published var isMasterMuted: Bool = false
    @Published var isAggregateActive: Bool = false
    @Published var statusMessage: String = "Inactive"

    let simplyCoreAudio = SimplyCoreAudio()
    let aggregateService = AggregateDeviceService()
    let volumeController = VolumeController()

    private var cancellables = Set<AnyCancellable>()
    private var aggregateDeviceID: AudioObjectID?
    private var aggregateDevice: AudioDevice?
    private var previousOutputDeviceID: AudioObjectID?
    private var isUpdatingVolume = false

    var enabledDevices: [BluetoothAudioDevice] {
        availableDevices.filter { $0.isEnabled }
    }

    var enabledCount: Int {
        enabledDevices.count
    }

    init() {
        refreshDeviceList()
        subscribeToNotifications()
        cleanupOrphanedAggregates()
    }

    deinit {
        teardownAggregate()
    }

    // MARK: - Device Discovery

    func refreshDeviceList() {
        let allOutputs = simplyCoreAudio.allOutputDevices
        let bluetoothDevices = allOutputs.filter { device in
            let transport = device.transportType
            return transport == .bluetooth || transport == .bluetoothLE
        }

        let previousEnabled = Set(availableDevices.filter { $0.isEnabled }.map { $0.id })

        availableDevices = bluetoothDevices.map { device in
            var btDevice = BluetoothAudioDevice(from: device)
            if previousEnabled.contains(btDevice.id) {
                btDevice.isEnabled = true
            }
            return btDevice
        }
    }

    // MARK: - Device Toggle

    func toggleDevice(_ device: BluetoothAudioDevice) {
        guard let index = availableDevices.firstIndex(where: { $0.id == device.id }) else { return }
        availableDevices[index].isEnabled.toggle()
        rebuildAggregateDevice()
    }

    // MARK: - Aggregate Device Management

    func rebuildAggregateDevice() {
        teardownAggregate()

        let enabled = enabledDevices
        guard enabled.count >= 2 else {
            if enabled.count == 1 {
                // Single device — just set it as default output
                setDefaultOutput(device: enabled[0].underlyingDevice)
                statusMessage = "Output: \(enabled[0].name)"
            } else {
                restorePreviousOutput()
                statusMessage = "Inactive"
            }
            isAggregateActive = false
            return
        }

        let subDeviceUIDs = enabled.compactMap { $0.uid }
        let clockSourceUID = enabled.first!.uid

        let result = aggregateService.createAggregateDevice(
            name: Constants.aggregateDeviceName,
            uid: Constants.aggregateDeviceUID,
            subDeviceUIDs: subDeviceUIDs,
            clockSourceUID: clockSourceUID
        )

        switch result {
        case .success(let deviceID):
            aggregateDeviceID = deviceID
            isAggregateActive = true
            statusMessage = "Active (\(enabled.count) devices)"

            if let aggDevice = AudioDevice.lookup(by: deviceID) {
                self.aggregateDevice = aggDevice
                savePreviousOutput()
                setDefaultOutput(device: aggDevice)

                // Sync master slider to aggregate device's current volume
                if let currentVol = aggDevice.virtualMainVolume(scope: .output) {
                    masterVolume = currentVol
                }
            }

        case .failure(let error):
            statusMessage = error.localizedDescription
            isAggregateActive = false
        }
    }

    func teardownAggregate() {
        guard let deviceID = aggregateDeviceID else { return }
        aggregateService.destroyAggregateDevice(id: deviceID)
        aggregateDeviceID = nil
        aggregateDevice = nil
        isAggregateActive = false
    }

    // MARK: - Volume Control

    func setDeviceVolume(_ device: BluetoothAudioDevice, volume: Float) {
        guard let index = availableDevices.firstIndex(where: { $0.id == device.id }) else { return }
        availableDevices[index].volume = volume
        volumeController.setVolume(volume, for: device.underlyingDevice)
    }

    func setMasterVolume(_ volume: Float) {
        isUpdatingVolume = true
        defer { isUpdatingVolume = false }

        masterVolume = volume
        isMasterMuted = volume == 0

        // Set volume on the aggregate device itself (this is what system volume keys control)
        if let aggDevice = aggregateDevice {
            aggDevice.setVirtualMainVolume(volume, scope: .output)
        }

        // Also set on each sub-device for individual control
        for device in enabledDevices {
            setDeviceVolume(device, volume: volume)
        }
    }

    func toggleMasterMute() {
        if isMasterMuted {
            isMasterMuted = false
            let vol = masterVolume > 0 ? masterVolume : Constants.defaultMasterVolume
            setMasterVolume(vol)
        } else {
            isMasterMuted = true
            isUpdatingVolume = true
            defer { isUpdatingVolume = false }
            if let aggDevice = aggregateDevice {
                aggDevice.setVirtualMainVolume(0, scope: .output)
            }
            for device in enabledDevices {
                volumeController.setVolume(0, for: device.underlyingDevice)
            }
        }
    }

    // MARK: - Disconnect Handling

    func handleDeviceDisconnection(_ deviceID: AudioObjectID) {
        guard let index = availableDevices.firstIndex(where: { $0.id == deviceID }) else { return }
        availableDevices[index].isConnected = false
        availableDevices[index].isEnabled = false
        rebuildAggregateDevice()
    }

    // MARK: - Private

    private func subscribeToNotifications() {
        NotificationCenter.default.publisher(for: .deviceListChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDeviceList()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .deviceIsAliveDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let device = notification.object as? AudioDevice {
                    if !device.isAlive {
                        self?.handleDeviceDisconnection(device.id)
                    } else {
                        self?.refreshDeviceList()
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .deviceVolumeDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self, !self.isUpdatingVolume,
                      let device = notification.object as? AudioDevice else { return }

                // If the aggregate device volume changed (e.g. system volume keys),
                // sync our master slider and propagate to sub-devices
                if let aggID = self.aggregateDeviceID, device.id == aggID {
                    if let newVolume = device.virtualMainVolume(scope: .output) {
                        self.masterVolume = newVolume
                        self.isMasterMuted = newVolume == 0
                        // Propagate to all sub-devices
                        for enabledDevice in self.enabledDevices {
                            self.volumeController.setVolume(newVolume, for: enabledDevice.underlyingDevice)
                            if let idx = self.availableDevices.firstIndex(where: { $0.id == enabledDevice.id }) {
                                self.availableDevices[idx].volume = newVolume
                            }
                        }
                    }
                    return
                }

                // Individual sub-device volume changed externally
                if let index = self.availableDevices.firstIndex(where: { $0.id == device.id }) {
                    let newVolume = device.virtualMainVolume(scope: .output) ?? self.availableDevices[index].volume
                    self.availableDevices[index].volume = newVolume
                }
            }
            .store(in: &cancellables)
    }

    private func savePreviousOutput() {
        if previousOutputDeviceID == nil {
            previousOutputDeviceID = simplyCoreAudio.defaultOutputDevice?.id
        }
    }

    private func restorePreviousOutput() {
        guard let prevID = previousOutputDeviceID,
              let device = AudioDevice.lookup(by: prevID) else { return }
        setDefaultOutput(device: device)
        previousOutputDeviceID = nil
    }

    private func setDefaultOutput(device: AudioDevice) {
        device.isDefaultOutputDevice = true
    }

    private func cleanupOrphanedAggregates() {
        let allDevices = simplyCoreAudio.allOutputDevices
        for device in allDevices {
            if device.uid?.hasPrefix("com.airsplit") == true {
                aggregateService.destroyAggregateDevice(id: device.id)
            }
        }
    }
}
