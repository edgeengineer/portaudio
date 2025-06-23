import CPortAudio
import Foundation

/// Information about an audio device.
///
/// This structure contains detailed information about an audio input or output device,
/// including its capabilities, channel counts, and latency characteristics.
///
/// ## Topics
/// ### Device Properties
/// - ``index``
/// - ``name``
/// - ``hostApi``
/// ### Channel Information
/// - ``maxInputChannels``
/// - ``maxOutputChannels``
/// ### Latency Information
/// - ``defaultLowInputLatency``
/// - ``defaultLowOutputLatency``
/// - ``defaultHighInputLatency``
/// - ``defaultHighOutputLatency``
/// ### Sample Rate
/// - ``defaultSampleRate``
public struct DeviceInfo {
    /// The device index used to identify this device.
    public let index: Int
    
    /// The human-readable name of the device.
    public let name: String
    
    /// The index of the host API this device belongs to.
    public let hostApi: Int
    
    /// Maximum number of input channels supported.
    ///
    /// Zero if this device doesn't support input.
    public let maxInputChannels: Int
    
    /// Maximum number of output channels supported.
    ///
    /// Zero if this device doesn't support output.
    public let maxOutputChannels: Int
    
    /// Default latency for low-latency input mode, in seconds.
    public let defaultLowInputLatency: TimeInterval
    
    /// Default latency for low-latency output mode, in seconds.
    public let defaultLowOutputLatency: TimeInterval
    
    /// Default latency for high-latency input mode, in seconds.
    public let defaultHighInputLatency: TimeInterval
    
    /// Default latency for high-latency output mode, in seconds.
    public let defaultHighOutputLatency: TimeInterval
    
    /// The default sample rate for this device in Hz.
    public let defaultSampleRate: Double
    
    init?(index: Int) {
        guard let deviceInfo = Pa_GetDeviceInfo(PaDeviceIndex(index)) else {
            return nil
        }
        
        self.index = index
        self.name = String(cString: deviceInfo.pointee.name)
        self.hostApi = Int(deviceInfo.pointee.hostApi)
        self.maxInputChannels = Int(deviceInfo.pointee.maxInputChannels)
        self.maxOutputChannels = Int(deviceInfo.pointee.maxOutputChannels)
        self.defaultLowInputLatency = deviceInfo.pointee.defaultLowInputLatency
        self.defaultLowOutputLatency = deviceInfo.pointee.defaultLowOutputLatency
        self.defaultHighInputLatency = deviceInfo.pointee.defaultHighInputLatency
        self.defaultHighOutputLatency = deviceInfo.pointee.defaultHighOutputLatency
        self.defaultSampleRate = deviceInfo.pointee.defaultSampleRate
    }
}

extension PortAudio {
    /// Gets information about a specific audio device.
    ///
    /// - Parameter index: The device index (0 to ``deviceCount`` - 1)
    /// - Returns: Device information, or nil if the index is invalid
    public static func getDeviceInfo(at index: Int) -> DeviceInfo? {
        return DeviceInfo(index: index)
    }
    
    /// Gets information about all available audio devices.
    ///
    /// - Returns: An array of all audio devices on the system
    /// - Note: This includes both input and output devices
    public static func getAllDevices() -> [DeviceInfo] {
        let count = deviceCount
        return (0..<count).compactMap { getDeviceInfo(at: $0) }
    }
    
    /// Gets all devices that support audio input.
    ///
    /// - Returns: An array of devices with at least one input channel
    public static func getInputDevices() -> [DeviceInfo] {
        return getAllDevices().filter { $0.maxInputChannels > 0 }
    }
    
    /// Gets all devices that support audio output.
    ///
    /// - Returns: An array of devices with at least one output channel
    public static func getOutputDevices() -> [DeviceInfo] {
        return getAllDevices().filter { $0.maxOutputChannels > 0 }
    }
}