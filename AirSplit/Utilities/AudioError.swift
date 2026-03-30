import Foundation

enum AudioError: LocalizedError {
    case aggregateCreationFailed(OSStatus)
    case aggregateDestructionFailed(OSStatus)
    case deviceNotFound(String)
    case volumeSetFailed(String)
    case noDevicesSelected
    case sampleRateMismatch

    var errorDescription: String? {
        switch self {
        case .aggregateCreationFailed(let status):
            return "Failed to create aggregate device (error \(status))"
        case .aggregateDestructionFailed(let status):
            return "Failed to destroy aggregate device (error \(status))"
        case .deviceNotFound(let name):
            return "Device not found: \(name)"
        case .volumeSetFailed(let name):
            return "Failed to set volume for: \(name)"
        case .noDevicesSelected:
            return "No devices selected for multi-output"
        case .sampleRateMismatch:
            return "Devices have incompatible sample rates"
        }
    }
}
