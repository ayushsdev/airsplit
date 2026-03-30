import SwiftUI

struct DeviceRowView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager
    let deviceIndex: Int

    private var device: BluetoothAudioDevice {
        audioManager.availableDevices[deviceIndex]
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(device.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                Image(systemName: deviceIcon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(device.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { audioManager.availableDevices[deviceIndex].isEnabled },
                    set: { _ in audioManager.toggleDevice(device) }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
            }

            if device.isEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { audioManager.availableDevices[deviceIndex].volume },
                            set: { newValue in
                                audioManager.setDeviceVolume(device, volume: newValue)
                            }
                        ),
                        in: 0...1
                    )
                    .controlSize(.small)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(Int(device.volume * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }
                .padding(.leading, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(device.isEnabled ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: device.isEnabled)
    }

    private var deviceIcon: String {
        let name = device.name.lowercased()
        if name.contains("airpods") || name.contains("headphone") || name.contains("buds") {
            return "headphones"
        } else {
            return "hifispeaker.fill"
        }
    }
}
