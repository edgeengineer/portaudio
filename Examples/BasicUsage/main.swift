import PortAudio
import Foundation

// Example of basic PortAudio usage in Swift

do {
    // Initialize PortAudio
    try PortAudio.initialize()
    defer { try? PortAudio.terminate() }
    
    print("PortAudio Version: \(PortAudio.versionText)")
    print("Device Count: \(PortAudio.deviceCount)")
    
    // List all audio devices
    let devices = PortAudio.getAllDevices()
    for device in devices {
        print("Device \(device.index): \(device.name)")
        print("  Input channels: \(device.maxInputChannels)")
        print("  Output channels: \(device.maxOutputChannels)")
        print("  Default sample rate: \(device.defaultSampleRate)")
        print("")
    }
    
    // Get default devices
    if let defaultInput = PortAudio.defaultInputDevice {
        print("Default input device: \(defaultInput)")
    }
    
    if let defaultOutput = PortAudio.defaultOutputDevice {
        print("Default output device: \(defaultOutput)")
        
        // Create a simple blocking stream for output
        let stream = AudioStream()
        
        let outputParams = StreamParameters(
            device: defaultOutput,
            channelCount: 2,
            sampleFormat: .float32,
            suggestedLatency: 0.05
        )
        
        try stream.open(
            outputParameters: outputParams,
            sampleRate: 44100.0,
            framesPerBuffer: 256
        )
        
        print("Stream opened successfully!")
        print("Stream is active: \(stream.isActive)")
        print("Stream is stopped: \(stream.isStopped)")
        
        try stream.close()
        print("Stream closed successfully!")
    }
    
} catch {
    print("Error: \(error)")
}