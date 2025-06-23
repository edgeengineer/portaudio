import Testing
import Foundation
@testable import PortAudio

struct CallbackTests {
    
    @Test("Callback stream creation throws error (not yet implemented)")
    func testCallbackStreamCreation() throws {
        try PortAudio.initialize()
        defer { try? PortAudio.terminate() }
        let outputDevice = PortAudio.defaultOutputDevice
        #expect(outputDevice != nil, "No default output device available")
        
        guard let outputDeviceIndex = outputDevice else {
            return // Skip test if no output device available
        }
        
        let callback: StreamCallback = { input, output, frameCount, timeInfo, flags in
            // Simple sine wave generator
            if var outputBuffer = AudioBuffer<Float>.from(rawPointer: output, frameCount: Int(frameCount), channelCount: 2) {
                let frequency: Float = 440.0 // A4 note
                let sampleRate: Float = 44100.0
                
                for frame in 0..<outputBuffer.frameCount {
                    let time = Float(frame) / sampleRate
                    let sample = sin(2.0 * Float.pi * frequency * time) * 0.1 // Low volume
                    
                    // Stereo output
                    outputBuffer[frame, 0] = sample
                    outputBuffer[frame, 1] = sample
                }
            }
            
            return .continue
        }
        
        let stream = AudioStream(callback: callback)
        
        let outputParams = StreamParameters(
            device: outputDeviceIndex,
            channelCount: 2,
            sampleFormat: .float32,
            suggestedLatency: 0.05
        )
        
        // For now, callback streams are not implemented, so we expect an error
        #expect(throws: PortAudioError.internalError) {
            try stream.open(
                outputParameters: outputParams,
                sampleRate: 44100.0,
                framesPerBuffer: 256
            )
        }
    }
    
    @Test("Blocking stream creation and closure")
    func testBlockingStreamCreation() throws {
        try PortAudio.initialize()
        defer { try? PortAudio.terminate() }
        
        let outputDevice = PortAudio.defaultOutputDevice
        #expect(outputDevice != nil, "No default output device available")
        
        guard let outputDeviceIndex = outputDevice else {
            return // Skip test if no output device available
        }
        
        let stream = AudioStream()
        
        let outputParams = StreamParameters(
            device: outputDeviceIndex,
            channelCount: 2,
            sampleFormat: .float32,
            suggestedLatency: 0.05
        )
        
        try stream.open(
            outputParameters: outputParams,
            sampleRate: 44100.0,
            framesPerBuffer: 256
        )
        
        try stream.close()
    }
}