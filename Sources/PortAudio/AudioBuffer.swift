import CPortAudio
import Foundation

/// A type-safe wrapper for interleaved audio buffers.
///
/// AudioBuffer provides convenient access to multi-channel audio data
/// in interleaved format (samples from different channels are stored consecutively).
///
/// ## Example
/// ```swift
/// // In a stream callback:
/// if let outputBuffer = AudioBuffer<Float>.from(
///     rawPointer: output,
///     frameCount: Int(frameCount),
///     channelCount: 2
/// ) {
///     // Generate a stereo sine wave
///     for frame in 0..<outputBuffer.frameCount {
///         let sample = sin(phase) * 0.5
///         outputBuffer[frame, 0] = Float(sample) // Left channel
///         outputBuffer[frame, 1] = Float(sample) // Right channel
///         phase += phaseIncrement
///     }
/// }
/// ```
///
/// ## Topics
/// ### Creating Buffers
/// - ``init(data:frameCount:channelCount:)``
/// - ``from(rawPointer:frameCount:channelCount:)``
/// ### Accessing Data
/// - ``subscript(_:_:)``
/// - ``frame(at:)``
/// ### Buffer Properties
/// - ``data``
/// - ``frameCount``
/// - ``channelCount``
public struct AudioBuffer<T> {
    /// The underlying pointer to the audio data.
    public let data: UnsafeMutablePointer<T>
    
    /// The number of audio frames in the buffer.
    public let frameCount: Int
    
    /// The number of channels per frame.
    public let channelCount: Int
    
    /// Creates an audio buffer wrapper.
    ///
    /// - Parameters:
    ///   - data: Pointer to the interleaved audio data
    ///   - frameCount: Number of frames in the buffer
    ///   - channelCount: Number of channels per frame
    public init(data: UnsafeMutablePointer<T>, frameCount: Int, channelCount: Int) {
        self.data = data
        self.frameCount = frameCount
        self.channelCount = channelCount
    }
    
    /// Accesses a sample at the specified frame and channel.
    ///
    /// - Parameters:
    ///   - frame: The frame index (0 to frameCount-1)
    ///   - channel: The channel index (0 to channelCount-1)
    /// - Returns: The sample value
    /// - Precondition: Both indices must be within bounds
    public subscript(frame: Int, channel: Int) -> T {
        get {
            precondition(frame >= 0 && frame < frameCount, "Frame index out of bounds")
            precondition(channel >= 0 && channel < channelCount, "Channel index out of bounds")
            return data[frame * channelCount + channel]
        }
        set {
            precondition(frame >= 0 && frame < frameCount, "Frame index out of bounds")
            precondition(channel >= 0 && channel < channelCount, "Channel index out of bounds")
            data[frame * channelCount + channel] = newValue
        }
    }
    
    /// Gets a pointer to the start of a specific frame.
    ///
    /// - Parameter index: The frame index
    /// - Returns: Pointer to the first sample of the frame
    /// - Precondition: Index must be within bounds
    public func frame(at index: Int) -> UnsafeMutablePointer<T> {
        precondition(index >= 0 && index < frameCount, "Frame index out of bounds")
        return data + (index * channelCount)
    }
}

// MARK: - Type-specific Factory Methods

public extension AudioBuffer where T == Float {
    /// Creates a Float audio buffer from a raw pointer.
    ///
    /// - Parameters:
    ///   - rawPointer: The raw pointer from a stream callback
    ///   - frameCount: Number of frames
    ///   - channelCount: Number of channels
    /// - Returns: An AudioBuffer, or nil if the pointer is nil
    static func from(rawPointer: UnsafeMutableRawPointer?, frameCount: Int, channelCount: Int) -> AudioBuffer<Float>? {
        guard let pointer = rawPointer?.assumingMemoryBound(to: Float.self) else {
            return nil
        }
        return AudioBuffer(data: pointer, frameCount: frameCount, channelCount: channelCount)
    }
}

public extension AudioBuffer where T == Int16 {
    /// Creates an Int16 audio buffer from a raw pointer.
    ///
    /// - Parameters:
    ///   - rawPointer: The raw pointer from a stream callback
    ///   - frameCount: Number of frames
    ///   - channelCount: Number of channels
    /// - Returns: An AudioBuffer, or nil if the pointer is nil
    static func from(rawPointer: UnsafeMutableRawPointer?, frameCount: Int, channelCount: Int) -> AudioBuffer<Int16>? {
        guard let pointer = rawPointer?.assumingMemoryBound(to: Int16.self) else {
            return nil
        }
        return AudioBuffer(data: pointer, frameCount: frameCount, channelCount: channelCount)
    }
}

public extension AudioBuffer where T == Int32 {
    /// Creates an Int32 audio buffer from a raw pointer.
    ///
    /// - Parameters:
    ///   - rawPointer: The raw pointer from a stream callback
    ///   - frameCount: Number of frames
    ///   - channelCount: Number of channels
    /// - Returns: An AudioBuffer, or nil if the pointer is nil
    static func from(rawPointer: UnsafeMutableRawPointer?, frameCount: Int, channelCount: Int) -> AudioBuffer<Int32>? {
        guard let pointer = rawPointer?.assumingMemoryBound(to: Int32.self) else {
            return nil
        }
        return AudioBuffer(data: pointer, frameCount: frameCount, channelCount: channelCount)
    }
}