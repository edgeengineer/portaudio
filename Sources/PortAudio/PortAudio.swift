import CPortAudio
import Foundation

/// Errors that can occur when using PortAudio.
///
/// These errors map directly to PortAudio's error codes and provide
/// Swift-friendly error handling for all PortAudio operations.
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
    
    /// Converts a PortAudio error code to a Swift error.
    /// - Parameter paError: The PortAudio error code
    /// - Returns: The corresponding Swift error, or nil if no error
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

/// The main interface to the PortAudio library.
///
/// PortAudio provides cross-platform audio I/O functionality. Before using any
/// PortAudio functionality, you must call ``initialize()``. When you're done,
/// call ``terminate()`` to clean up resources.
///
/// ## Example
/// ```swift
/// do {
///     try PortAudio.initialize()
///     defer { try? PortAudio.terminate() }
///     
///     // Use PortAudio functionality here
///     let deviceCount = PortAudio.deviceCount
///     print("Found \(deviceCount) audio devices")
/// } catch {
///     print("Failed to initialize PortAudio: \(error)")
/// }
/// ```
public struct PortAudio {
    /// Initializes the PortAudio library.
    ///
    /// This function must be called before using any other PortAudio functionality.
    /// It initializes internal data structures and performs platform-specific setup.
    ///
    /// - Throws: ``PortAudioError`` if initialization fails
    /// - Important: Always pair with ``terminate()`` when done
    public static func initialize() throws {
        let error = Pa_Initialize()
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// Terminates the PortAudio library.
    ///
    /// This function deallocates all resources allocated by PortAudio.
    /// It must be called when you're done using PortAudio.
    ///
    /// - Throws: ``PortAudioError`` if termination fails
    /// - Important: Don't use any PortAudio functionality after calling this
    public static func terminate() throws {
        let error = Pa_Terminate()
        if let paError = PortAudioError.from(error) {
            throw paError
        }
    }
    
    /// The numeric version of PortAudio.
    ///
    /// The version is encoded as a single integer with the format: `MMmmpp`
    /// where MM is major version, mm is minor version, and pp is patch level.
    public static var version: Int {
        return Int(Pa_GetVersion())
    }
    
    /// The human-readable version string of PortAudio.
    ///
    /// Returns a string like "PortAudio V19.7.0-devel, revision 147dd722548358763a8b649b3e4b41dfffbcfbb6"
    public static var versionText: String {
        return String(cString: Pa_GetVersionText())
    }
    
    /// The number of available audio devices.
    ///
    /// This includes both input and output devices. Use ``getDeviceInfo(at:)``
    /// to get information about each device.
    public static var deviceCount: Int {
        return Int(Pa_GetDeviceCount())
    }
    
    /// The index of the default input device, if available.
    ///
    /// - Returns: The device index, or nil if no default input device exists
    public static var defaultInputDevice: Int? {
        let device = Pa_GetDefaultInputDevice()
        return device == paNoDevice ? nil : Int(device)
    }
    
    /// The index of the default output device, if available.
    ///
    /// - Returns: The device index, or nil if no default output device exists
    public static var defaultOutputDevice: Int? {
        let device = Pa_GetDefaultOutputDevice()
        return device == paNoDevice ? nil : Int(device)
    }
    
    /// Gets information about the last host error.
    ///
    /// Host errors are platform-specific errors that occurred in the
    /// host API layer. This can provide more detailed error information
    /// than the generic PortAudio error codes.
    ///
    /// - Returns: A tuple containing the error code and message, or nil if no host error
    public static var lastHostError: (code: Int, message: String)? {
        guard let info = Pa_GetLastHostErrorInfo() else { return nil }
        let errorCode = Int(info.pointee.errorCode)
        
        // Only return if there's actually an error
        guard errorCode != 0 else { return nil }
        
        let message = String(cString: info.pointee.errorText)
        return (code: errorCode, message: message)
    }
}
