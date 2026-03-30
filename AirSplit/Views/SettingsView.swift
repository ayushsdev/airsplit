import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // General
            VStack(alignment: .leading, spacing: 8) {
                Text("General")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        updateLaunchAtLogin(newValue)
                    }
                    .controlSize(.small)
            }

            Divider()

            // About
            HStack {
                Text("AirSplit")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("v1.0.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            Text("Multi-output Bluetooth audio for macOS")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = !enabled
        }
    }
}
