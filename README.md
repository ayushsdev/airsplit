# AirSplit

Multi-output Bluetooth audio for macOS. Play audio to multiple Bluetooth speakers and headphones simultaneously with individual volume control per device.

## Features

- **Multi-device output** — Send audio to 2+ Bluetooth devices at the same time
- **Individual volume control** — Adjust volume per device independently
- **Master volume** — Control all devices at once, synced with macOS system volume keys
- **Menu bar app** — Lives in your menu bar, no dock icon clutter
- **Auto-discovery** — Detects Bluetooth audio devices automatically
- **Drift correction** — Keeps devices in sync using CoreAudio drift compensation
- **Graceful disconnect handling** — Automatically rebuilds when a device drops
- **Launch at login** — Optional setting to start with macOS

## How It Works

AirSplit creates a CoreAudio [aggregate device](https://support.apple.com/en-us/102171) that combines multiple Bluetooth outputs into a single virtual device. When you toggle on 2+ devices, AirSplit:

1. Creates a multi-output aggregate device
2. Sets it as your system default output
3. Enables drift correction for audio sync
4. Gives you per-device volume sliders

## Requirements

- macOS 13.0 (Ventura) or later
- 2+ Bluetooth audio devices

## Installation

### From source

```bash
git clone https://github.com/ayushsdev/airsplit.git
cd airsplit
swift build -c release
.build/release/AirSplit
```

### From Xcode

```bash
open AirSplit.xcodeproj
```

Select your signing team, then Product > Run.

## Usage

1. Connect your Bluetooth speakers/headphones via System Settings > Bluetooth
2. Click the AirSplit icon in the menu bar
3. Toggle on the devices you want to use
4. Adjust individual volume sliders or the master volume
5. Audio now plays through all selected devices

## Project Structure

```
AirSplit/
├── App/AirSplitApp.swift              — Menu bar app entry point
├── Models/BluetoothAudioDevice.swift  — Bluetooth device model
├── Services/
│   ├── AudioDeviceManager.swift       — Device discovery, aggregate management
│   ├── AggregateDeviceService.swift   — CoreAudio aggregate device creation
│   └── VolumeController.swift         — Per-device volume control
├── Views/
│   ├── MenuBarView.swift              — Main popover UI
│   ├── DeviceListView.swift           — Device list
│   ├── DeviceRowView.swift            — Device toggle + volume slider
│   ├── MasterVolumeView.swift         — Master volume + mute
│   ├── StatusIndicatorView.swift      — Active/inactive status
│   └── SettingsView.swift             — Inline settings panel
└── Utilities/
    ├── Constants.swift
    └── AudioError.swift
```

## Tech Stack

- **Swift** + **SwiftUI**
- **CoreAudio HAL** — Aggregate device creation and volume control
- **[SimplyCoreAudio](https://github.com/rnine/SimplyCoreAudio)** — Swift wrapper for device enumeration and notifications
- **XcodeGen** — Xcode project generation from `project.yml`

## Known Limitations

- Bluetooth audio has inherent latency (40-100ms). Drift correction helps but perfect sync across devices is a hardware limitation.
- All devices in the aggregate must support a common sample rate (typically 48kHz).
- Creating aggregate devices may require disabling App Sandbox for distribution outside the App Store.

## License

MIT
