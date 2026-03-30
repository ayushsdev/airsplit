import SwiftUI

@main
struct AirSplitApp: App {
    @StateObject private var audioManager = AudioDeviceManager()

    var body: some Scene {
        MenuBarExtra("AirSplit", systemImage: "airplayaudio") {
            MenuBarView()
                .environmentObject(audioManager)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)
    }
}
