import CPortAudio
import Foundation

/// Audio sample formats supported by PortAudio.
///
/// Choose the format that matches your audio data. Float32 is recommended
/// for most applications as it provides good precision and is widely supported.
public enum SampleFormat {
    /// 32-bit floating point samples (-1.0 to 1.0)
    case float32
    /// 32-bit signed integer samples
    case int32
    /// 24-bit signed integer samples (packed)
    case int24
    /// 16-bit signed integer samples
    case int16
    /// 8-bit signed integer samples
    case int8
    /// 8-bit unsigned integer samples
    case uint8
    
    var paSampleFormat: PaSampleFormat {
        switch self {
        case .float32: return paFloat32
        case .int32: return paInt32
        case .int24: return paInt24
        case .int16: return paInt16
        case .int8: return paInt8
        case .uint8: return paUInt8
        }
    }
}

/// Parameters for configuring an audio stream.
///
/// Use this structure to specify the device, channel count, sample format,
/// and latency requirements for audio input or output.
///
/// ## Example
/// ```swift
/// let outputParams = StreamParameters(
///     device: PortAudio.defaultOutputDevice!,
///     channelCount: 2,  // Stereo
///     sampleFormat: .float32,
///     suggestedLatency: 0.05  // 50ms
/// )
/// ```
public struct StreamParameters {
    /// The device index to use for this stream.
    public let device: Int
    
    /// The number of channels (1 for mono, 2 for stereo, etc.).
    public let channelCount: Int
    
    /// The sample format for audio data.
    public let sampleFormat: SampleFormat
    
    /// Suggested latency in seconds.
    ///
    /// Lower values reduce delay but may cause glitches.
    /// Typical values: 0.01-0.05 for low latency, 0.1-0.2 for stable playback.
    public let suggestedLatency: TimeInterval
    
    /// Creates stream parameters.
    ///
    /// - Parameters:
    ///   - device: The device index
    ///   - channelCount: Number of channels
    ///   - sampleFormat: Audio sample format
    ///   - suggestedLatency: Desired latency in seconds
    public init(device: Int, channelCount: Int, sampleFormat: SampleFormat, suggestedLatency: TimeInterval) {
        self.device = device
        self.channelCount = channelCount
        self.sampleFormat = sampleFormat
        self.suggestedLatency = suggestedLatency
    }
    
    var paStreamParameters: PaStreamParameters {
        return PaStreamParameters(
            device: PaDeviceIndex(device),
            channelCount: Int32(channelCount),
            sampleFormat: sampleFormat.paSampleFormat,
            suggestedLatency: suggestedLatency,
            hostApiSpecificStreamInfo: nil
        )
    }
}

/// Return values for stream callbacks.
///
/// Your callback should return one of these values to control stream behavior.
public enum StreamCallbackResult: Int32 {
    /// Continue normal stream operation.
    case `continue` = 0
    /// Stop the stream gracefully after this callback.
    case complete = 1
    /// Stop the stream immediately.
    case abort = 2
}

/// Timing information provided to stream callbacks.
///
/// These timestamps help with synchronization and latency compensation.
public struct StreamCallbackTimeInfo {
    /// The time when the first sample of the input buffer was captured at the ADC.
    public let inputBufferAdcTime: Double
    
    /// The current time according to the stream's clock.
    public let currentTime: Double
    
    /// The time when the first sample of the output buffer will output at the DAC.
    public let outputBufferDacTime: Double
    
    init(from paTimeInfo: PaStreamCallbackTimeInfo) {
        self.inputBufferAdcTime = paTimeInfo.inputBufferAdcTime
        self.currentTime = paTimeInfo.currentTime
        self.outputBufferDacTime = paTimeInfo.outputBufferDacTime
    }
}

/// Status flags passed to stream callbacks.
///
/// These flags indicate various conditions that may require attention.
public struct StreamCallbackFlags: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Input underflow occurred (not enough input data available).
    public static let inputUnderflow = StreamCallbackFlags(rawValue: 1)
    
    /// Input overflow occurred (input data was discarded).
    public static let inputOverflow = StreamCallbackFlags(rawValue: 2)
    
    /// Output underflow occurred (not enough output data provided).
    public static let outputUnderflow = StreamCallbackFlags(rawValue: 4)
    
    /// Output overflow occurred (output data was discarded).
    public static let outputOverflow = StreamCallbackFlags(rawValue: 8)
    
    /// The stream is priming, initial output buffers are being filled.
    public static let primingOutput = StreamCallbackFlags(rawValue: 16)
}

/// A callback function for processing audio in real-time.
///
/// - Parameters:
///   - input: Pointer to input buffer, or nil for output-only streams
///   - output: Pointer to output buffer, or nil for input-only streams  
///   - frameCount: Number of frames to process
///   - timeInfo: Timing information for synchronization
///   - statusFlags: Flags indicating stream status
/// - Returns: Result indicating whether to continue, complete, or abort
///
/// - Important: This function is called from a real-time thread. Avoid:
///   - Memory allocation
///   - File I/O
///   - Network operations
///   - Locks that might block
///   - Objective-C/Swift runtime operations
public typealias StreamCallback = (UnsafeRawPointer?, UnsafeMutableRawPointer?, UInt, StreamCallbackTimeInfo, StreamCallbackFlags) -> StreamCallbackResult

private class CallbackWrapper {
    let callback: StreamCallback
    
    init(callback: @escaping StreamCallback) {
        self.callback = callback
    }
}

/// An audio stream for input and/or output.
///
/// AudioStream provides both blocking and callback-based audio I/O.
/// For simple use cases, create a stream without a callback and use
/// ``read(into:frames:)`` and ``write(from:frames:)`` for blocking I/O.
/// For real-time applications, provide a callback function.
///
/// ## Blocking I/O Example
/// ```swift
/// let stream = AudioStream()
/// try stream.open(
///     outputParameters: outputParams,
///     sampleRate: 44100,
///     framesPerBuffer: 256
/// )
/// try stream.start()
/// 
/// // Write audio data
/// let buffer = UnsafeMutablePointer<Float>.allocate(capacity: 512)
/// defer { buffer.deallocate() }
/// // ... fill buffer with audio data ...
/// try stream.write(from: buffer, frames: 256)
/// 
/// try stream.stop()
/// try stream.close()
/// ```
///
/// ## Topics
/// ### Creating Streams
/// - ``init()``
/// - ``init(callback:)``
/// ### Stream Control
/// - ``open(inputParameters:outputParameters:sampleRate:framesPerBuffer:flags:)``
/// - ``start()``
/// - ``stop()``
/// - ``abort()``
/// - ``close()``
/// ### Stream State
/// - ``isActive``
/// - ``isStopped``
/// ### Blocking I/O
/// - ``read(into:frames:)``
/// - ``write(from:frames:)``
public class AudioStream {
    private var stream: UnsafeMutableRawPointer?
    private var callbackWrapper: CallbackWrapper?
    
    /// Creates a stream for blocking I/O.
    public init() {
        self.callbackWrapper = nil
    }
    
    /// Creates a stream with a callback for real-time processing.
    ///
    /// - Parameter callback: The function to call when audio data is needed
    /// - Note: Callback streams don't support blocking I/O methods
    public init(callback: @escaping StreamCallback) {
        self.callbackWrapper = CallbackWrapper(callback: callback)
    }
    
    deinit {
        try? close()
    }
    
    /// Opens the audio stream with the specified parameters.
    ///
    /// - Parameters:
    ///   - inputParameters: Parameters for audio input, or nil for output-only
    ///   - outputParameters: Parameters for audio output, or nil for input-only
    ///   - sampleRate: Sample rate in Hz (e.g., 44100, 48000)
    ///   - framesPerBuffer: Preferred buffer size, or 0 for automatic
    ///   - flags: Additional stream flags (usually 0)
    /// - Throws: ``PortAudioError`` if the stream cannot be opened
    /// - Important: At least one of inputParameters or outputParameters must be provided
    public func open(inputParameters: StreamParameters? = nil,
                    outputParameters: StreamParameters? = nil,
                    sampleRate: Double,
                    framesPerBuffer: UInt = 0,
                    flags: PaStreamFlags = 0) throws {
        
        var inputParams: PaStreamParameters?
        var outputParams: PaStreamParameters?
        
        if let input = inputParameters {
            inputParams = input.paStreamParameters
        }
        
        if let output = outputParameters {
            outputParams = output.paStreamParameters
        }
        
        let error: PaError
        if self.callbackWrapper != nil {
            throw PortAudioError.internalError
        } else {
            if var inputP = inputParams {
                if var outputP = outputParams {
                    error = Pa_OpenStream(&stream, &inputP, &outputP, sampleRate, UInt(framesPerBuffer), flags, nil, nil)
                } else {
                    error = Pa_OpenStream(&stream, &inputP, nil, sampleRate, UInt(framesPerBuffer), flags, nil, nil)
                }
            } else if var outputP = outputParams {
                error = Pa_OpenStream(&stream, nil, &outputP, sampleRate, UInt(framesPerBuffer), flags, nil, nil)
            } else {
                error = Pa_OpenStream(&stream, nil, nil, sampleRate, UInt(framesPerBuffer), flags, nil, nil)
            }
        }
        
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Starts audio processing.
    ///
    /// - Throws: ``PortAudioError`` if the stream cannot be started
    public func start() throws {
        guard let stream = stream else { return }
        let error = Pa_StartStream(stream)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Stops audio processing gracefully.
    ///
    /// Waits for pending buffers to complete before stopping.
    /// - Throws: ``PortAudioError`` if the stream cannot be stopped
    public func stop() throws {
        guard let stream = stream else { return }
        let error = Pa_StopStream(stream)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Stops audio processing immediately.
    ///
    /// Discards any pending buffers. Use ``stop()`` for graceful shutdown.
    /// - Throws: ``PortAudioError`` if the stream cannot be aborted
    public func abort() throws {
        guard let stream = stream else { return }
        let error = Pa_AbortStream(stream)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Closes the stream and releases resources.
    ///
    /// - Throws: ``PortAudioError`` if the stream cannot be closed
    /// - Note: The stream cannot be used after calling this method
    public func close() throws {
        guard let stream = stream else { return }
        
        let error = Pa_CloseStream(stream)
        self.stream = nil
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Whether the stream is currently processing audio.
    public var isActive: Bool {
        guard let stream = stream else { return false }
        return Pa_IsStreamActive(stream) == 1
    }
    
    /// Whether the stream is stopped.
    public var isStopped: Bool {
        guard let stream = stream else { return true }
        return Pa_IsStreamStopped(stream) == 1
    }
    
    /// Reads audio data from an input stream (blocking).
    ///
    /// - Parameters:
    ///   - buffer: Buffer to store the audio data
    ///   - frames: Number of frames to read
    /// - Throws: ``PortAudioError`` if reading fails
    /// - Note: Only available for blocking streams (created without callback)
    /// - Important: The buffer must have space for `frames * channelCount` samples
    public func read<T>(into buffer: UnsafeMutablePointer<T>, frames: UInt) throws {
        guard let stream = stream else { return }
        let error = Pa_ReadStream(stream, buffer, frames)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Writes audio data to an output stream (blocking).
    ///
    /// - Parameters:
    ///   - buffer: Buffer containing the audio data
    ///   - frames: Number of frames to write
    /// - Throws: ``PortAudioError`` if writing fails
    /// - Note: Only available for blocking streams (created without callback)
    /// - Important: The buffer must contain `frames * channelCount` samples
    public func write<T>(from buffer: UnsafePointer<T>, frames: UInt) throws {
        guard let stream = stream else { return }
        let error = Pa_WriteStream(stream, buffer, frames)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
}