import PortAudio
import Foundation

// Example demonstrating callback-based real-time audio generation
// This creates a stereo sine wave generator with different frequencies in each channel

class SineWaveGenerator {
    var leftPhase: Float = 0.0
    var rightPhase: Float = 0.0
    let leftFrequency: Float = 440.0  // A4
    let rightFrequency: Float = 554.365  // C#5 (major third)
    let sampleRate: Float = 44100.0
    let amplitude: Float = 0.3
    
    func generateStereoCallback() -> StreamCallback {
        return { [self] input, output, frameCount, timeInfo, flags in
            // Check if we have an output buffer
            guard var outputBuffer = AudioBuffer<Float>.from(
                rawPointer: output,
                frameCount: Int(frameCount),
                channelCount: 2
            ) else {
                return .abort
            }
            
            // Calculate phase increments
            let leftPhaseIncrement = 2.0 * Float.pi * leftFrequency / sampleRate
            let rightPhaseIncrement = 2.0 * Float.pi * rightFrequency / sampleRate
            
            // Generate samples
            for frame in 0..<outputBuffer.frameCount {
                // Generate sine waves
                let leftSample = sin(leftPhase) * amplitude
                let rightSample = sin(rightPhase) * amplitude
                
                // Write to buffer
                outputBuffer[frame, 0] = leftSample  // Left channel
                outputBuffer[frame, 1] = rightSample  // Right channel
                
                // Advance phases
                leftPhase += leftPhaseIncrement
                rightPhase += rightPhaseIncrement
                
                // Wrap phases to prevent numeric overflow
                if leftPhase >= 2.0 * Float.pi {
                    leftPhase -= 2.0 * Float.pi
                }
                if rightPhase >= 2.0 * Float.pi {
                    rightPhase -= 2.0 * Float.pi
                }
            }
            
            return .continue
        }
    }
}

// Demonstrate using stream info and monitoring
func demonstrateCallbackStream() throws {
    print("=== PortAudio Callback Stream Example ===\n")
    
    // Initialize PortAudio
    try PortAudio.initialize()
    defer { try? PortAudio.terminate() }
    
    print("PortAudio Version: \(PortAudio.versionText)")
    print("Host APIs available: \(PortAudio.hostAPICount)")
    
    // List host APIs
    print("\nAvailable Host APIs:")
    for api in PortAudio.getAllHostAPIs() {
        print("  \(api.index): \(api.name) - \(api.deviceCount) devices")
    }
    
    // Get default output device
    guard let outputDevice = PortAudio.defaultOutputDevice else {
        print("No default output device found!")
        return
    }
    
    let deviceInfo = PortAudio.getDeviceInfo(at: outputDevice)!
    print("\nUsing output device: \(deviceInfo.name)")
    print("  Max channels: \(deviceInfo.maxOutputChannels)")
    print("  Default sample rate: \(deviceInfo.defaultSampleRate) Hz")
    print("  Low latency: \(deviceInfo.defaultLowOutputLatency * 1000) ms")
    
    // Create output parameters
    let outputParams = StreamParameters(
        device: outputDevice,
        channelCount: 2,  // Stereo
        sampleFormat: .float32,
        suggestedLatency: deviceInfo.defaultLowOutputLatency
    )
    
    // Check if format is supported
    let formatSupported = PortAudio.isFormatSupported(
        outputParameters: outputParams,
        sampleRate: 44100
    )
    print("\nFormat supported: \(formatSupported)")
    
    // Calculate buffer size
    let sampleSize = SampleFormat.float32.sampleSize
    print("Sample size: \(sampleSize) bytes")
    
    // Create the generator and stream
    let generator = SineWaveGenerator()
    let stream = AudioStream(callback: generator.generateStereoCallback())
    
    // Set a finished callback
    stream.setFinishedCallback {
        print("\nStream finished callback triggered!")
    }
    
    // Open the stream with flags
    try stream.open(
        outputParameters: outputParams,
        sampleRate: 44100,
        framesPerBuffer: 256,
        flags: [.clipOff, .ditherOff]  // Disable clipping and dithering
    )
    
    // Get stream info
    if let info = stream.info {
        print("\nStream Info:")
        print("  Actual sample rate: \(info.sampleRate) Hz")
        print("  Output latency: \(info.outputLatency * 1000) ms")
    }
    
    // Start the stream
    try stream.start()
    print("\nPlaying stereo sine wave...")
    print("Left channel: \(generator.leftFrequency) Hz (A4)")
    print("Right channel: \(generator.rightFrequency) Hz (C#5)")
    print("Press Ctrl+C to stop\n")
    
    // Monitor stream status
    var lastCpuLoad: Double = 0
    for _ in 0..<50 {  // Run for 5 seconds (100ms intervals)
        PortAudio.sleep(milliseconds: 100)
        
        // Check stream status
        if stream.isActive {
            let cpuLoad = stream.cpuLoad
            let currentTime = stream.currentTime
            
            // Only print if CPU load changed significantly
            if abs(cpuLoad - lastCpuLoad) > 0.01 {
                print(String(format: "Time: %.2f s, CPU Load: %.1f%%", 
                           currentTime, cpuLoad * 100))
                lastCpuLoad = cpuLoad
            }
            
            // Check available write space (for monitoring)
            let writeAvailable = stream.writeAvailable
            if writeAvailable < 256 {
                print("Warning: Low write buffer space: \(writeAvailable) frames")
            }
        }
    }
    
    // Stop the stream
    print("\nStopping stream...")
    try stream.stop()
    
    // The stream should be stopped now
    print("Stream stopped: \(stream.isStopped)")
    
    // Close the stream
    try stream.close()
    print("Stream closed successfully")
}

// Run the example
do {
    try demonstrateCallbackStream()
} catch {
    print("Error: \(error)")
    if let hostError = PortAudio.lastHostError {
        print("Host error: \(hostError.message) (code: \(hostError.code))")
    }
}