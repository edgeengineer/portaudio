import PortAudio
import Foundation

// Cross-platform sine wave generator example
// This works on both macOS and Linux without requiring AVFoundation

class SineWavePlayer {
    private var stream: AudioStream?
    private var phase: Double = 0.0
    private let frequency: Double
    private let sampleRate: Double
    private let amplitude: Float
    
    init(frequency: Double = 440.0, sampleRate: Double = 44100.0, amplitude: Float = 0.5) {
        self.frequency = frequency
        self.sampleRate = sampleRate
        self.amplitude = amplitude
    }
    
    func play(duration: TimeInterval) throws {
        // Initialize PortAudio
        try PortAudio.initialize()
        defer { try? PortAudio.terminate() }
        
        print("Playing \(frequency) Hz sine wave for \(duration) seconds...")
        
        // Get the default output device
        guard let defaultOutput = PortAudio.defaultOutputDevice else {
            throw PortAudioError.deviceUnavailable
        }
        
        // Configure output parameters
        let outputParams = StreamParameters(
            device: defaultOutput,
            channelCount: 2, // Stereo
            sampleFormat: .float32,
            suggestedLatency: 0.05
        )
        
        // Create and open the stream
        stream = AudioStream()
        try stream?.open(
            outputParameters: outputParams,
            sampleRate: sampleRate,
            framesPerBuffer: 256
        )
        
        try stream?.start()
        
        // Generate and play sine wave
        let bufferSize = 256
        let buffer = UnsafeMutablePointer<Float>.allocate(capacity: bufferSize * 2) // stereo
        defer { buffer.deallocate() }
        
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < duration {
            // Generate sine wave samples
            for frame in 0..<bufferSize {
                let sample = amplitude * Float(sin(phase))
                buffer[frame * 2] = sample     // Left channel
                buffer[frame * 2 + 1] = sample // Right channel
                
                // Update phase
                phase += 2.0 * .pi * frequency / sampleRate
                
                // Keep phase in reasonable range
                if phase > 2.0 * .pi {
                    phase -= 2.0 * .pi
                }
            }
            
            try stream?.write(from: buffer, frames: UInt(bufferSize))
        }
        
        try stream?.stop()
        try stream?.close()
        
        print("Playback completed.")
    }
}

// Example usage
func demonstrateSineWavePlayback() {
    do {
        // Play different frequencies
        let frequencies = [440.0, 523.25, 659.25, 783.99] // A4, C5, E5, G5
        
        for freq in frequencies {
            print("\nPlaying frequency: \(freq) Hz")
            let player = SineWavePlayer(frequency: freq, amplitude: 0.3)
            try player.play(duration: 0.5)
            Thread.sleep(forTimeInterval: 0.1) // Small pause between notes
        }
        
    } catch {
        print("Error playing sine wave: \(error)")
    }
}