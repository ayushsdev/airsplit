import SwiftUI

struct StatusIndicatorView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(audioManager.isAggregateActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)

            Text(audioManager.statusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
