import Testing
@testable import PortAudio

struct PortAudioTests {
    
    @Test("PortAudio initialization and termination")
    func testInitializationAndTermination() throws {
        try PortAudio.initialize()
        
        let version = PortAudio.version
        #expect(version > 0, "Version should be positive")
        
        let versionText = PortAudio.versionText
        #expect(!versionText.isEmpty, "Version text should not be empty")
        
        let deviceCount = PortAudio.deviceCount
        #expect(deviceCount >= 0, "Device count should be non-negative")
        
        try PortAudio.terminate()
    }
    
    @Test("Device enumeration")
    func testDeviceEnumeration() throws {
        try PortAudio.initialize()
        defer { try? PortAudio.terminate() }
        
        let devices = PortAudio.getAllDevices()
        #expect(devices.count == PortAudio.deviceCount, "Device array count should match device count")
        
        let inputDevices = PortAudio.getInputDevices()
        let outputDevices = PortAudio.getOutputDevices()
        
        for device in inputDevices {
            #expect(device.maxInputChannels > 0, "Input device should have input channels")
        }
        
        for device in outputDevices {
            #expect(device.maxOutputChannels > 0, "Output device should have output channels")
        }
    }
}
