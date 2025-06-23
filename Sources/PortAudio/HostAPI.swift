import CPortAudio
import Foundation

/// Types of audio host APIs supported by PortAudio.
public enum HostAPIType: Int {
    case inDevelopment = 0
    case directSound = 1
    case mme = 2
    case asio = 3
    case soundManager = 4
    case coreAudio = 5
    case oss = 7
    case alsa = 8
    case al = 9
    case beOS = 10
    case wdmks = 11
    case jack = 12
    case wasapi = 13
    case audioScienceHPI = 14
    case audioIO = 15
    
    var name: String {
        switch self {
        case .inDevelopment: return "In Development"
        case .directSound: return "DirectSound"
        case .mme: return "MME"
        case .asio: return "ASIO"
        case .soundManager: return "Sound Manager"
        case .coreAudio: return "Core Audio"
        case .oss: return "OSS"
        case .alsa: return "ALSA"
        case .al: return "AL"
        case .beOS: return "BeOS"
        case .wdmks: return "WDMKS"
        case .jack: return "JACK"
        case .wasapi: return "WASAPI"
        case .audioScienceHPI: return "AudioScience HPI"
        case .audioIO: return "AudioIO"
        }
    }
}

/// Information about a host API.
///
/// Host APIs are the platform-specific audio subsystems that PortAudio
/// can use (e.g., Core Audio on macOS, ALSA on Linux, WASAPI on Windows).
public struct HostAPIInfo {
    /// The host API index.
    public let index: Int
    
    /// The type of this host API.
    public let type: HostAPIType
    
    /// The name of the host API.
    public let name: String
    
    /// The number of devices provided by this host API.
    public let deviceCount: Int
    
    /// The default input device for this host API, or nil if none.
    public let defaultInputDevice: Int?
    
    /// The default output device for this host API, or nil if none.
    public let defaultOutputDevice: Int?
    
    init?(index: Int) {
        guard let info = Pa_GetHostApiInfo(PaHostApiIndex(index)) else {
            return nil
        }
        
        self.index = index
        self.type = HostAPIType(rawValue: Int(info.pointee.type.rawValue)) ?? .inDevelopment
        self.name = String(cString: info.pointee.name)
        self.deviceCount = Int(info.pointee.deviceCount)
        
        // Convert host-specific device indices to global indices
        if info.pointee.defaultInputDevice >= 0 {
            self.defaultInputDevice = Int(Pa_HostApiDeviceIndexToDeviceIndex(
                PaHostApiIndex(index),
                info.pointee.defaultInputDevice
            ))
        } else {
            self.defaultInputDevice = nil
        }
        
        if info.pointee.defaultOutputDevice >= 0 {
            self.defaultOutputDevice = Int(Pa_HostApiDeviceIndexToDeviceIndex(
                PaHostApiIndex(index),
                info.pointee.defaultOutputDevice
            ))
        } else {
            self.defaultOutputDevice = nil
        }
    }
}

extension PortAudio {
    /// The number of available host APIs.
    public static var hostAPICount: Int {
        return Int(Pa_GetHostApiCount())
    }
    
    /// Gets information about a specific host API.
    ///
    /// - Parameter index: The host API index (0 to ``hostAPICount`` - 1)
    /// - Returns: Host API information, or nil if the index is invalid
    public static func getHostAPIInfo(at index: Int) -> HostAPIInfo? {
        return HostAPIInfo(index: index)
    }
    
    /// Gets all available host APIs.
    ///
    /// - Returns: An array of all host APIs on the system
    public static func getAllHostAPIs() -> [HostAPIInfo] {
        let count = hostAPICount
        return (0..<count).compactMap { getHostAPIInfo(at: $0) }
    }
    
    /// Gets the default host API.
    ///
    /// - Returns: The default host API information, or nil if none
    public static var defaultHostAPI: HostAPIInfo? {
        let index = Pa_GetDefaultHostApi()
        guard index >= 0 else { return nil }
        return getHostAPIInfo(at: Int(index))
    }
    
    /// Finds a host API by type.
    ///
    /// - Parameter type: The host API type to search for
    /// - Returns: The host API information, or nil if not found
    public static func hostAPI(ofType type: HostAPIType) -> HostAPIInfo? {
        let index = Pa_HostApiTypeIdToHostApiIndex(PaHostApiTypeId(rawValue: PaHostApiTypeId.RawValue(type.rawValue)))
        guard index >= 0 else { return nil }
        return getHostAPIInfo(at: Int(index))
    }
    
    /// Validates if a stream format is supported.
    ///
    /// Use this to check if specific stream parameters will work before
    /// attempting to open a stream.
    ///
    /// - Parameters:
    ///   - inputParameters: Input stream parameters, or nil for output-only
    ///   - outputParameters: Output stream parameters, or nil for input-only
    ///   - sampleRate: The sample rate in Hz
    /// - Returns: true if the format is supported, false otherwise
    public static func isFormatSupported(
        inputParameters: StreamParameters? = nil,
        outputParameters: StreamParameters? = nil,
        sampleRate: Double
    ) -> Bool {
        var inputParams: PaStreamParameters?
        var outputParams: PaStreamParameters?
        
        if let input = inputParameters {
            inputParams = input.paStreamParameters
        }
        
        if let output = outputParameters {
            outputParams = output.paStreamParameters
        }
        
        var error: PaError = 0
        
        if let inputParams = inputParams {
            if let outputParams = outputParams {
                // Both input and output
                withUnsafePointer(to: inputParams) { inputPtr in
                    withUnsafePointer(to: outputParams) { outputPtr in
                        error = Pa_IsFormatSupported(inputPtr, outputPtr, sampleRate)
                    }
                }
            } else {
                // Input only
                withUnsafePointer(to: inputParams) { inputPtr in
                    error = Pa_IsFormatSupported(inputPtr, nil, sampleRate)
                }
            }
        } else if let outputParams = outputParams {
            // Output only
            withUnsafePointer(to: outputParams) { outputPtr in
                error = Pa_IsFormatSupported(nil, outputPtr, sampleRate)
            }
        } else {
            // No parameters provided
            return false
        }
        
        return error == 0 // paFormatIsSupported
    }
}