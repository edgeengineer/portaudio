import CPortAudio
import Foundation

public enum SampleFormat {
    case float32
    case int32
    case int24
    case int16
    case int8
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

public struct StreamParameters {
    public let device: Int
    public let channelCount: Int
    public let sampleFormat: SampleFormat
    public let suggestedLatency: TimeInterval
    
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

public enum StreamCallbackResult: Int32 {
    case `continue` = 0
    case complete = 1
    case abort = 2
}

public struct StreamCallbackTimeInfo {
    public let inputBufferAdcTime: Double
    public let currentTime: Double
    public let outputBufferDacTime: Double
    
    init(from paTimeInfo: PaStreamCallbackTimeInfo) {
        self.inputBufferAdcTime = paTimeInfo.inputBufferAdcTime
        self.currentTime = paTimeInfo.currentTime
        self.outputBufferDacTime = paTimeInfo.outputBufferDacTime
    }
}

public struct StreamCallbackFlags: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let inputUnderflow = StreamCallbackFlags(rawValue: 1)
    public static let inputOverflow = StreamCallbackFlags(rawValue: 2)
    public static let outputUnderflow = StreamCallbackFlags(rawValue: 4)
    public static let outputOverflow = StreamCallbackFlags(rawValue: 8)
    public static let primingOutput = StreamCallbackFlags(rawValue: 16)
}

public typealias StreamCallback = (UnsafeRawPointer?, UnsafeMutableRawPointer?, UInt, StreamCallbackTimeInfo, StreamCallbackFlags) -> StreamCallbackResult

private class CallbackWrapper {
    let callback: StreamCallback
    
    init(callback: @escaping StreamCallback) {
        self.callback = callback
    }
}

public class AudioStream {
    private var stream: UnsafeMutableRawPointer?
    private var callbackWrapper: CallbackWrapper?
    
    public init() {
        self.callbackWrapper = nil
    }
    
    public init(callback: @escaping StreamCallback) {
        self.callbackWrapper = CallbackWrapper(callback: callback)
    }
    
    deinit {
        try? close()
    }
    
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
    
    public func start() throws {
        guard let stream = stream else { return }
        let error = Pa_StartStream(stream)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public func stop() throws {
        guard let stream = stream else { return }
        let error = Pa_StopStream(stream)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public func abort() throws {
        guard let stream = stream else { return }
        let error = Pa_AbortStream(stream)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public func close() throws {
        guard let stream = stream else { return }
        
        let error = Pa_CloseStream(stream)
        self.stream = nil
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public var isActive: Bool {
        guard let stream = stream else { return false }
        return Pa_IsStreamActive(stream) == 1
    }
    
    public var isStopped: Bool {
        guard let stream = stream else { return true }
        return Pa_IsStreamStopped(stream) == 1
    }
    
    public func read<T>(into buffer: UnsafeMutablePointer<T>, frames: UInt) throws {
        guard let stream = stream else { return }
        let error = Pa_ReadStream(stream, buffer, frames)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public func write<T>(from buffer: UnsafePointer<T>, frames: UInt) throws {
        guard let stream = stream else { return }
        let error = Pa_WriteStream(stream, buffer, frames)
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
}