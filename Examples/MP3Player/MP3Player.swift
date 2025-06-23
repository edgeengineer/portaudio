import PortAudio
import AVFoundation
import Foundation

// Example of playing MP3 files using AVFoundation for decoding and PortAudio for playback

class MP3Player {
    private var stream: AudioStream?
    private var audioFile: AVAudioFile?
    private var isPlaying = false
    
    func play(mp3URL: URL) throws {
        // Initialize PortAudio if not already initialized
        try PortAudio.initialize()
        
        // Open the MP3 file with AVFoundation
        audioFile = try AVAudioFile(forReading: mp3URL)
        guard let audioFile = audioFile else {
            throw NSError(domain: "MP3Player", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open audio file"])
        }
        
        let format = audioFile.processingFormat
        print("MP3 File Info:")
        print("  Sample Rate: \(format.sampleRate) Hz")
        print("  Channels: \(format.channelCount)")
        print("  Duration: \(Double(audioFile.length) / format.sampleRate) seconds")
        
        // Get the default output device
        guard let defaultOutput = PortAudio.defaultOutputDevice else {
            throw PortAudioError.deviceUnavailable
        }
        
        // Configure output parameters
        let outputParams = StreamParameters(
            device: defaultOutput,
            channelCount: Int(format.channelCount),
            sampleFormat: .float32,
            suggestedLatency: 0.05
        )
        
        // Create and open the stream
        stream = AudioStream()
        try stream?.open(
            outputParameters: outputParams,
            sampleRate: format.sampleRate,
            framesPerBuffer: 1024
        )
        
        try stream?.start()
        isPlaying = true
        
        print("Playing MP3 file...")
        
        // Read and play the file in chunks
        let bufferSize: AVAudioFrameCount = 1024
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize)!
        
        while audioFile.framePosition < audioFile.length && isPlaying {
            // Read audio data from file
            try audioFile.read(into: buffer)
            
            if buffer.frameLength == 0 {
                break
            }
            
            // Get the audio data
            let channelCount = Int(format.channelCount)
            let frameCount = Int(buffer.frameLength)
            
            if channelCount == 1 {
                // Mono audio
                if let floatData = buffer.floatChannelData?[0] {
                    try stream?.write(from: floatData, frames: UInt(frameCount))
                }
            } else if channelCount == 2 {
                // Stereo audio - need to interleave channels
                if let leftChannel = buffer.floatChannelData?[0],
                   let rightChannel = buffer.floatChannelData?[1] {
                    
                    // Create interleaved buffer
                    let interleavedBuffer = UnsafeMutablePointer<Float>.allocate(capacity: frameCount * 2)
                    defer { interleavedBuffer.deallocate() }
                    
                    for i in 0..<frameCount {
                        interleavedBuffer[i * 2] = leftChannel[i]
                        interleavedBuffer[i * 2 + 1] = rightChannel[i]
                    }
                    
                    try stream?.write(from: interleavedBuffer, frames: UInt(frameCount))
                }
            } else {
                // Multi-channel audio (>2 channels)
                let interleavedBuffer = UnsafeMutablePointer<Float>.allocate(capacity: frameCount * channelCount)
                defer { interleavedBuffer.deallocate() }
                
                // Interleave all channels
                for frame in 0..<frameCount {
                    for channel in 0..<channelCount {
                        if let channelData = buffer.floatChannelData?[channel] {
                            interleavedBuffer[frame * channelCount + channel] = channelData[frame]
                        }
                    }
                }
                
                try stream?.write(from: interleavedBuffer, frames: UInt(frameCount))
            }
        }
        
        print("Playback finished.")
        try stop()
    }
    
    func stop() throws {
        isPlaying = false
        
        if let stream = stream {
            try stream.stop()
            try stream.close()
            self.stream = nil
        }
        
        audioFile = nil
    }
    
    deinit {
        try? stop()
        try? PortAudio.terminate()
    }
}

// Example usage
func demonstrateMP3Playback() {
    do {
        let player = MP3Player()
        
        // Get the path to sample.mp3 in the same directory as this file
        let currentFilePath = URL(fileURLWithPath: #file)
        let examplesDirectory = currentFilePath.deletingLastPathComponent()
        let mp3Path = examplesDirectory.appendingPathComponent("sample.mp3").path
        let mp3URL = URL(fileURLWithPath: mp3Path)
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: mp3Path) {
            print("Playing sample.mp3 from: \(mp3Path)")
            try player.play(mp3URL: mp3URL)
        } else {
            print("sample.mp3 not found at: \(mp3Path)")
            print("Please ensure sample.mp3 is in the Examples directory")
        }
        
    } catch {
        print("Error playing MP3: \(error)")
    }
}