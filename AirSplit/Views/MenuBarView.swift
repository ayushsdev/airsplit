import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                settingsPanel
            } else {
                mainPanel
            }
        }
    }

    // MARK: - Main Panel

    private var mainPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "airplayaudio")
                    .font(.title3)
                Text("AirSplit")
                    .font(.headline)
                Spacer()
                StatusIndicatorView()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Device list
            if audioManager.availableDevices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wave.3.right.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Bluetooth audio devices found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Connect a Bluetooth speaker or headphones to get started.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            } else {
                DeviceListView()
                    .padding(.vertical, 8)
            }

            Divider()

            // Master volume
            if !audioManager.enabledDevices.isEmpty {
                MasterVolumeView()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                Divider()
            }

            // Footer
            HStack {
                Button(action: { audioManager.refreshDeviceList() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Refresh device list")

                Spacer()

                Button(action: { withAnimation { showSettings = true } }) {
                    Image(systemName: "gear")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Settings")

                Spacer()

                Button("Quit") {
                    audioManager.teardownAggregate()
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: { withAnimation { showSettings = false } }) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            SettingsView()
                .padding(.vertical, 4)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Quit") {
                    audioManager.teardownAggregate()
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
