import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(audioManager.availableDevices.enumerated()), id: \.element.id) { index, _ in
                DeviceRowView(deviceIndex: index)
            }
        }
        .padding(.horizontal, 12)
    }
}
