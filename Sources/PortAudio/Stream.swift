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
    
    /// Gets the size of a single sample in bytes.
    ///
    /// Useful for calculating buffer sizes.
    /// - Returns: The size in bytes of one sample in this format
    public var sampleSize: Int {
        return Int(Pa_GetSampleSize(paSampleFormat))
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

/// Stream open flags that modify stream behavior.
///
/// These flags can be combined to control various aspects of stream operation.
public struct StreamFlags: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// No flags (default behavior).
    public static let noFlag = StreamFlags([])
    
    /// Disable default clipping of out-of-range samples.
    public static let clipOff = StreamFlags(rawValue: 1)
    
    /// Disable default dithering of output samples.
    public static let ditherOff = StreamFlags(rawValue: 2)
    
    /// Never drop input samples; request that input overflow conditions be ignored.
    public static let neverDropInput = StreamFlags(rawValue: 4)
    
    /// Call the stream callback to fill initial output buffers.
    public static let primeOutputBuffersUsingStreamCallback = StreamFlags(rawValue: 8)
}

/// Information about an open audio stream.
///
/// Contains the actual stream parameters after opening, which may differ
/// from the requested parameters.
public struct StreamInfo {
    /// The input latency of the stream in seconds.
    ///
    /// For full-duplex streams, this includes all processing between the
    /// input hardware and the stream callback.
    public let inputLatency: TimeInterval
    
    /// The output latency of the stream in seconds.
    ///
    /// For full-duplex streams, this includes all processing between the
    /// stream callback and the output hardware.
    public let outputLatency: TimeInterval
    
    /// The sample rate of the stream in Hz.
    ///
    /// This is the actual rate, which should match the requested rate
    /// unless an error occurred.
    public let sampleRate: Double
    
    init?(from paStreamInfo: UnsafePointer<PaStreamInfo>?) {
        guard let info = paStreamInfo?.pointee else { return nil }
        self.inputLatency = info.inputLatency
        self.outputLatency = info.outputLatency
        self.sampleRate = info.sampleRate
    }
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

// C callback function that bridges to Swift
private func paStreamCallback(
    input: UnsafeRawPointer?,
    output: UnsafeMutableRawPointer?,
    frameCount: UInt,
    timeInfo: UnsafePointer<PaStreamCallbackTimeInfo>?,
    statusFlags: PaStreamCallbackFlags,
    userData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let wrapper = userData?.assumingMemoryBound(to: CallbackWrapper.self).pointee else {
        return StreamCallbackResult.abort.rawValue
    }
    
    let swiftTimeInfo = StreamCallbackTimeInfo(from: timeInfo!.pointee)
    let swiftFlags = StreamCallbackFlags(rawValue: UInt(statusFlags))
    
    let result = wrapper.callback(input, output, frameCount, swiftTimeInfo, swiftFlags)
    return result.rawValue
}

// C callback function for stream finished notifications
private func paStreamFinishedCallback(userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else { return }
    
    let wrapper = Unmanaged<CallbackWrapper>.fromOpaque(userData).takeUnretainedValue()
    wrapper.finishedCallback?()
}

private class CallbackWrapper {
    let callback: StreamCallback
    var finishedCallback: (() -> Void)?
    
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
    ///   - flags: Additional stream flags
    /// - Throws: ``PortAudioError`` if the stream cannot be opened
    /// - Important: At least one of inputParameters or outputParameters must be provided
    public func open(inputParameters: StreamParameters? = nil,
                    outputParameters: StreamParameters? = nil,
                    sampleRate: Double,
                    framesPerBuffer: UInt = 0,
                    flags: StreamFlags = []) throws {
        
        var inputParams: PaStreamParameters?
        var outputParams: PaStreamParameters?
        
        if let input = inputParameters {
            inputParams = input.paStreamParameters
        }
        
        if let output = outputParameters {
            outputParams = output.paStreamParameters
        }
        
        let error: PaError
        let paFlags = PaStreamFlags(flags.rawValue)
        
        if let wrapper = callbackWrapper {
            // Callback-based stream
            let callbackPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(wrapper).toOpaque())
            
            if var inputP = inputParams {
                if var outputP = outputParams {
                    error = Pa_OpenStream(&stream, &inputP, &outputP, sampleRate, UInt(framesPerBuffer), paFlags, paStreamCallback, callbackPtr)
                } else {
                    error = Pa_OpenStream(&stream, &inputP, nil, sampleRate, UInt(framesPerBuffer), paFlags, paStreamCallback, callbackPtr)
                }
            } else if var outputP = outputParams {
                error = Pa_OpenStream(&stream, nil, &outputP, sampleRate, UInt(framesPerBuffer), paFlags, paStreamCallback, callbackPtr)
            } else {
                throw PortAudioError.invalidDevice
            }
        } else {
            // Blocking stream
            if var inputP = inputParams {
                if var outputP = outputParams {
                    error = Pa_OpenStream(&stream, &inputP, &outputP, sampleRate, UInt(framesPerBuffer), paFlags, nil, nil)
                } else {
                    error = Pa_OpenStream(&stream, &inputP, nil, sampleRate, UInt(framesPerBuffer), paFlags, nil, nil)
                }
            } else if var outputP = outputParams {
                error = Pa_OpenStream(&stream, nil, &outputP, sampleRate, UInt(framesPerBuffer), paFlags, nil, nil)
            } else {
                throw PortAudioError.invalidDevice
            }
        }
        
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Opens a stream with default input and/or output devices.
    ///
    /// This is a convenience method for quickly setting up a stream with
    /// default devices. It's equivalent to manually creating StreamParameters
    /// with the default device indices.
    ///
    /// - Parameters:
    ///   - inputChannels: Number of input channels (0 for output-only)
    ///   - outputChannels: Number of output channels (0 for input-only)
    ///   - sampleFormat: The sample format to use
    ///   - sampleRate: Sample rate in Hz (e.g., 44100, 48000)
    ///   - framesPerBuffer: Preferred buffer size, or 0 for automatic
    ///   - flags: Additional stream flags
    /// - Throws: ``PortAudioError`` if the stream cannot be opened
    /// - Important: At least one of inputChannels or outputChannels must be non-zero
    public func openDefaultStream(inputChannels: Int = 0,
                                 outputChannels: Int = 0,
                                 sampleFormat: SampleFormat = .float32,
                                 sampleRate: Double,
                                 framesPerBuffer: UInt = 0,
                                 flags: StreamFlags = []) throws {
        guard inputChannels > 0 || outputChannels > 0 else {
            throw PortAudioError.invalidChannelCount
        }
        
        var inputParams: StreamParameters?
        var outputParams: StreamParameters?
        
        if inputChannels > 0 {
            guard let defaultInput = PortAudio.defaultInputDevice else {
                throw PortAudioError.invalidDevice
            }
            inputParams = StreamParameters(
                device: defaultInput,
                channelCount: inputChannels,
                sampleFormat: sampleFormat,
                suggestedLatency: 0.05  // Default latency
            )
        }
        
        if outputChannels > 0 {
            guard let defaultOutput = PortAudio.defaultOutputDevice else {
                throw PortAudioError.invalidDevice
            }
            outputParams = StreamParameters(
                device: defaultOutput,
                channelCount: outputChannels,
                sampleFormat: sampleFormat,
                suggestedLatency: 0.05  // Default latency
            )
        }
        
        try open(
            inputParameters: inputParams,
            outputParameters: outputParams,
            sampleRate: sampleRate,
            framesPerBuffer: framesPerBuffer,
            flags: flags
        )
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
    
    /// Sets a callback to be called when the stream finishes.
    ///
    /// The callback will be invoked when the stream stops naturally
    /// (e.g., when a callback returns `.complete`). This is useful
    /// for cleanup or notification when audio playback ends.
    ///
    /// - Parameter callback: The function to call when the stream finishes,
    ///                      or nil to remove the callback
    /// - Throws: ``PortAudioError`` if the callback cannot be set
    /// - Note: This is only supported for callback-based streams
    public func setStreamFinishedCallback(_ callback: (() -> Void)?) throws {
        guard let stream = stream else {
            throw PortAudioError.badStreamPtr
        }
        
        guard let wrapper = callbackWrapper else {
            throw PortAudioError.canNotWriteToACallbackStream
        }
        
        wrapper.finishedCallback = callback
        
        // Bridge to C callback
        let error = Pa_SetStreamFinishedCallback(stream, callback != nil ? paStreamFinishedCallback : nil)
        
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
    
    /// Gets the current time of the stream in seconds.
    ///
    /// The time is measured from when the stream was started.
    /// This is useful for synchronizing events with audio playback.
    ///
    /// - Returns: The current stream time in seconds
    public var currentTime: Double {
        guard let stream = stream else { return 0 }
        return Pa_GetStreamTime(stream)
    }
    
    /// Gets the CPU load of the stream as a fraction (0.0 to 1.0).
    ///
    /// This represents the CPU time spent in the stream callback as a fraction
    /// of real time. Values close to 1.0 indicate the callback is consuming
    /// most of the available CPU time.
    ///
    /// - Returns: CPU load fraction (0.0 to 1.0), or 0 if not available
    public var cpuLoad: Double {
        guard let stream = stream else { return 0 }
        return Pa_GetStreamCpuLoad(stream)
    }
    
    /// The number of frames that can be read without blocking.
    ///
    /// For input streams or full-duplex streams.
    /// - Returns: Number of frames available, or 0 if stream is output-only
    public var readAvailable: Int {
        guard let stream = stream else { return 0 }
        let available = Pa_GetStreamReadAvailable(stream)
        return available >= 0 ? Int(available) : 0
    }
    
    /// The number of frames that can be written without blocking.
    ///
    /// For output streams or full-duplex streams.
    /// - Returns: Number of frames available, or 0 if stream is input-only
    public var writeAvailable: Int {
        guard let stream = stream else { return 0 }
        let available = Pa_GetStreamWriteAvailable(stream)
        return available >= 0 ? Int(available) : 0
    }
    
    /// Gets information about the stream.
    ///
    /// Returns actual stream parameters which may differ from requested values.
    /// - Returns: Stream information, or nil if stream is not open
    public var info: StreamInfo? {
        guard let stream = stream else { return nil }
        return StreamInfo(from: Pa_GetStreamInfo(stream))
    }
    
    /// Sets a callback to be called when the stream finishes.
    ///
    /// The callback is called when the stream stops, whether due to
    /// completion, abort, or error. This is useful for cleanup operations
    /// or for being notified when a finite stream completes.
    ///
    /// - Parameter callback: The closure to call when the stream finishes,
    ///                      or nil to remove the callback
    /// - Note: Only available for callback-based streams
    public func setFinishedCallback(_ callback: (() -> Void)?) {
        // Store the callback in our wrapper
        // The actual C callback setup happens during stream open
        callbackWrapper?.finishedCallback = callback
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