import SwiftUI

struct MasterVolumeView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Master Volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 8) {
                Button(action: { audioManager.toggleMasterMute() }) {
                    Image(systemName: audioManager.isMasterMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(audioManager.isMasterMuted ? .red : .primary)
                }
                .buttonStyle(.plain)
                .help(audioManager.isMasterMuted ? "Unmute" : "Mute")

                Slider(
                    value: Binding(
                        get: { audioManager.masterVolume },
                        set: { audioManager.setMasterVolume($0) }
                    ),
                    in: 0...1
                )
                .controlSize(.small)

                Text("\(Int(audioManager.masterVolume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }
}
