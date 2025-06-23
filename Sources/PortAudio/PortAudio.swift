import CPortAudio
import Foundation

public enum PortAudioError: Error, LocalizedError, Equatable {
    case notInitialized
    case unanticipatedHostError
    case invalidChannelCount
    case invalidSampleRate
    case invalidDevice
    case invalidFlag
    case sampleFormatNotSupported
    case badIODeviceCombination
    case insufficientMemory
    case bufferTooBig
    case bufferTooSmall
    case nullCallback
    case badStreamPtr
    case timedOut
    case internalError
    case deviceUnavailable
    case incompatibleHostApiSpecificStreamInfo
    case streamIsStopped
    case streamIsNotStopped
    case inputOverflowed
    case outputUnderflowed
    case hostApiNotFound
    case invalidHostApi
    case canNotReadFromACallbackStream
    case canNotWriteToACallbackStream
    case canNotReadFromAnOutputOnlyStream
    case canNotWriteToAnInputOnlyStream
    case incompatibleStreamHostApi
    case badBufferPtr
    case unknownError(Int32)
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized: return "PortAudio not initialized"
        case .unanticipatedHostError: return "Unanticipated host error"
        case .invalidChannelCount: return "Invalid channel count"
        case .invalidSampleRate: return "Invalid sample rate"
        case .invalidDevice: return "Invalid device"
        case .invalidFlag: return "Invalid flag"
        case .sampleFormatNotSupported: return "Sample format not supported"
        case .badIODeviceCombination: return "Bad I/O device combination"
        case .insufficientMemory: return "Insufficient memory"
        case .bufferTooBig: return "Buffer too big"
        case .bufferTooSmall: return "Buffer too small"
        case .nullCallback: return "Null callback"
        case .badStreamPtr: return "Bad stream pointer"
        case .timedOut: return "Timed out"
        case .internalError: return "Internal error"
        case .deviceUnavailable: return "Device unavailable"
        case .incompatibleHostApiSpecificStreamInfo: return "Incompatible host API specific stream info"
        case .streamIsStopped: return "Stream is stopped"
        case .streamIsNotStopped: return "Stream is not stopped"
        case .inputOverflowed: return "Input overflowed"
        case .outputUnderflowed: return "Output underflowed"
        case .hostApiNotFound: return "Host API not found"
        case .invalidHostApi: return "Invalid host API"
        case .canNotReadFromACallbackStream: return "Cannot read from a callback stream"
        case .canNotWriteToACallbackStream: return "Cannot write to a callback stream"
        case .canNotReadFromAnOutputOnlyStream: return "Cannot read from an output-only stream"
        case .canNotWriteToAnInputOnlyStream: return "Cannot write to an input-only stream"
        case .incompatibleStreamHostApi: return "Incompatible stream host API"
        case .badBufferPtr: return "Bad buffer pointer"
        case .unknownError(let code): return "Unknown PortAudio error: \(code)"
        }
    }
    
    static func from(_ paError: PaError) -> PortAudioError? {
        switch paError {
        case paNoError.rawValue: return nil
        case paNotInitialized.rawValue: return .notInitialized
        case paUnanticipatedHostError.rawValue: return .unanticipatedHostError
        case paInvalidChannelCount.rawValue: return .invalidChannelCount
        case paInvalidSampleRate.rawValue: return .invalidSampleRate
        case paInvalidDevice.rawValue: return .invalidDevice
        case paInvalidFlag.rawValue: return .invalidFlag
        case paSampleFormatNotSupported.rawValue: return .sampleFormatNotSupported
        case paBadIODeviceCombination.rawValue: return .badIODeviceCombination
        case paInsufficientMemory.rawValue: return .insufficientMemory
        case paBufferTooBig.rawValue: return .bufferTooBig
        case paBufferTooSmall.rawValue: return .bufferTooSmall
        case paNullCallback.rawValue: return .nullCallback
        case paBadStreamPtr.rawValue: return .badStreamPtr
        case paTimedOut.rawValue: return .timedOut
        case paInternalError.rawValue: return .internalError
        case paDeviceUnavailable.rawValue: return .deviceUnavailable
        case paIncompatibleHostApiSpecificStreamInfo.rawValue: return .incompatibleHostApiSpecificStreamInfo
        case paStreamIsStopped.rawValue: return .streamIsStopped
        case paStreamIsNotStopped.rawValue: return .streamIsNotStopped
        case paInputOverflowed.rawValue: return .inputOverflowed
        case paOutputUnderflowed.rawValue: return .outputUnderflowed
        case paHostApiNotFound.rawValue: return .hostApiNotFound
        case paInvalidHostApi.rawValue: return .invalidHostApi
        case paCanNotReadFromACallbackStream.rawValue: return .canNotReadFromACallbackStream
        case paCanNotWriteToACallbackStream.rawValue: return .canNotWriteToACallbackStream
        case paCanNotReadFromAnOutputOnlyStream.rawValue: return .canNotReadFromAnOutputOnlyStream
        case paCanNotWriteToAnInputOnlyStream.rawValue: return .canNotWriteToAnInputOnlyStream
        case paIncompatibleStreamHostApi.rawValue: return .incompatibleStreamHostApi
        case paBadBufferPtr.rawValue: return .badBufferPtr
        default: return .unknownError(paError)
        }
    }
}

public struct PortAudio {
    public static func initialize() throws {
        let error = Pa_Initialize()
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public static func terminate() throws {
        let error = Pa_Terminate()
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    public static var version: Int {
        return Int(Pa_GetVersion())
    }
    
    public static var versionText: String {
        return String(cString: Pa_GetVersionText())
    }
    
    public static var deviceCount: Int {
        return Int(Pa_GetDeviceCount())
    }
    
    public static var defaultInputDevice: Int? {
        let device = Pa_GetDefaultInputDevice()
        return device == paNoDevice ? nil : Int(device)
    }
    
    public static var defaultOutputDevice: Int? {
        let device = Pa_GetDefaultOutputDevice()
        return device == paNoDevice ? nil : Int(device)
    }
}
