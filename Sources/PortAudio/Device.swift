import CPortAudio
import Foundation

public struct DeviceInfo {
    public let index: Int
    public let name: String
    public let hostApi: Int
    public let maxInputChannels: Int
    public let maxOutputChannels: Int
    public let defaultLowInputLatency: TimeInterval
    public let defaultLowOutputLatency: TimeInterval
    public let defaultHighInputLatency: TimeInterval
    public let defaultHighOutputLatency: TimeInterval
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
    public static func getDeviceInfo(at index: Int) -> DeviceInfo? {
        return DeviceInfo(index: index)
    }
    
    public static func getAllDevices() -> [DeviceInfo] {
        let count = deviceCount
        return (0..<count).compactMap { getDeviceInfo(at: $0) }
    }
    
    public static func getInputDevices() -> [DeviceInfo] {
        return getAllDevices().filter { $0.maxInputChannels > 0 }
    }
    
    public static func getOutputDevices() -> [DeviceInfo] {
        return getAllDevices().filter { $0.maxOutputChannels > 0 }
    }
}