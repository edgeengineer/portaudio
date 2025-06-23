# Missing PortAudio C API Functions in Swift Wrapper

This document lists all PortAudio C API functions that are available in the C header but not yet wrapped in our Swift implementation.

## 1. Version Information APIs

### ✅ Already Implemented
- `Pa_GetVersion()` - Wrapped as `PortAudio.version`
- `Pa_GetVersionText()` - Wrapped as `PortAudio.versionText`

### ❌ Missing
- **`Pa_GetVersionInfo()`** - Returns detailed version information structure
  - **Use case**: Get structured version info including major/minor/subminor version numbers and revision info
  - **Priority**: Low - Current text version is usually sufficient

## 2. Host API Functions

### ❌ Missing - All Host API functions
- **`Pa_GetHostApiCount()`** - Get number of available host APIs
  - **Use case**: Enumerate available audio subsystems (CoreAudio, WASAPI, ALSA, etc.)
  - **Priority**: Medium - Useful for advanced users

- **`Pa_GetDefaultHostApi()`** - Get the default host API index
  - **Use case**: Identify which audio subsystem is being used by default
  - **Priority**: Medium

- **`Pa_GetHostApiInfo()`** - Get information about a specific host API
  - **Use case**: Get name, device count, and default devices for a host API
  - **Priority**: Medium

- **`Pa_HostApiTypeIdToHostApiIndex()`** - Convert host API type to index
  - **Use case**: Find specific host API (e.g., find CoreAudio on macOS)
  - **Priority**: Low

- **`Pa_HostApiDeviceIndexToDeviceIndex()`** - Convert host API device index to PortAudio device index
  - **Use case**: Work with host-API-specific device enumeration
  - **Priority**: Low

## 3. Error Handling

### ✅ Already Implemented
- Error codes are mapped to Swift `PortAudioError` enum

### ❌ Missing
- **`Pa_GetErrorText()`** - Get human-readable error text from error code
  - **Use case**: Get PortAudio's error descriptions (though we provide our own)
  - **Priority**: Low - We already have Swift error descriptions

- **`Pa_GetLastHostErrorInfo()`** - Get detailed host API error information
  - **Use case**: Debug platform-specific audio errors
  - **Priority**: Medium - Useful for debugging

## 4. Stream Information and Timing

### ❌ Missing - All stream info/timing functions
- **`Pa_GetStreamInfo()`** - Get stream information (latencies, sample rate)
  - **Use case**: Query actual latencies and sample rate after stream is opened
  - **Priority**: High - Important for latency-sensitive applications

- **`Pa_GetStreamTime()`** - Get current stream time
  - **Use case**: Synchronize events with audio playback/recording
  - **Priority**: High - Essential for synchronization

- **`Pa_GetStreamCpuLoad()`** - Get CPU usage of stream callback
  - **Use case**: Monitor performance and optimize audio processing
  - **Priority**: Medium - Useful for performance tuning

## 5. Stream Control

### ✅ Already Implemented
- `Pa_OpenStream()` - Basic version wrapped
- `Pa_CloseStream()` - Wrapped as `stream.close()`
- `Pa_StartStream()` - Wrapped as `stream.start()`
- `Pa_StopStream()` - Wrapped as `stream.stop()`
- `Pa_AbortStream()` - Wrapped as `stream.abort()`
- `Pa_IsStreamActive()` - Wrapped as `stream.isActive`
- `Pa_IsStreamStopped()` - Wrapped as `stream.isStopped`

### ❌ Missing
- **`Pa_OpenDefaultStream()`** - Simplified stream opening with default devices
  - **Use case**: Quick setup for simple applications
  - **Priority**: Medium - Convenience function

- **`Pa_SetStreamFinishedCallback()`** - Register callback for when stream finishes
  - **Use case**: Get notified when stream stops (useful for file playback)
  - **Priority**: Medium

- **Callback-based streams** - Current implementation doesn't support callbacks properly
  - **Use case**: Real-time audio processing
  - **Priority**: High - Essential for most audio applications

## 6. Blocking I/O

### ✅ Already Implemented
- `Pa_ReadStream()` - Wrapped as `stream.read()`
- `Pa_WriteStream()` - Wrapped as `stream.write()`

### ❌ Missing
- **`Pa_GetStreamReadAvailable()`** - Get number of frames available to read
  - **Use case**: Non-blocking audio input, avoid blocking
  - **Priority**: High - Important for responsive applications

- **`Pa_GetStreamWriteAvailable()`** - Get number of frames that can be written
  - **Use case**: Non-blocking audio output, avoid blocking
  - **Priority**: High - Important for responsive applications

## 7. Format Support

### ❌ Missing
- **`Pa_IsFormatSupported()`** - Check if format is supported before opening stream
  - **Use case**: Validate parameters before attempting to open stream
  - **Priority**: Medium - Helpful for robust applications

## 8. Utility Functions

### ❌ Missing
- **`Pa_GetSampleSize()`** - Get size in bytes of a sample format
  - **Use case**: Buffer size calculations
  - **Priority**: Low - Can be calculated manually

- **`Pa_Sleep()`** - Cross-platform sleep function
  - **Use case**: Simple delays (mainly for examples/tests)
  - **Priority**: Low - Use Swift's sleep functions instead

## Priority Summary

### High Priority (Essential for most applications)
1. **Callback-based streams** - The current wrapper doesn't properly support callbacks
2. **`Pa_GetStreamInfo()`** - Query actual stream parameters
3. **`Pa_GetStreamTime()`** - Synchronization
4. **`Pa_GetStreamReadAvailable()`** - Non-blocking input
5. **`Pa_GetStreamWriteAvailable()`** - Non-blocking output

### Medium Priority (Useful for advanced use cases)
1. **Host API functions** - For multi-API systems
2. **`Pa_GetLastHostErrorInfo()`** - Debugging
3. **`Pa_GetStreamCpuLoad()`** - Performance monitoring
4. **`Pa_OpenDefaultStream()`** - Convenience
5. **`Pa_SetStreamFinishedCallback()`** - Completion notifications
6. **`Pa_IsFormatSupported()`** - Parameter validation

### Low Priority (Nice to have)
1. **`Pa_GetVersionInfo()`** - Structured version info
2. **`Pa_GetErrorText()`** - We have our own error descriptions
3. **`Pa_GetSampleSize()`** - Can be calculated
4. **`Pa_Sleep()`** - Use Swift alternatives
5. **`Pa_HostApiTypeIdToHostApiIndex()`** - Advanced host API usage
6. **`Pa_HostApiDeviceIndexToDeviceIndex()`** - Advanced host API usage

## Recommendations

The most critical missing functionality is:

1. **Proper callback support** - The current implementation has a callback wrapper but doesn't actually use it in `open()`. This is essential for real-time audio.

2. **Stream timing and availability functions** - These are crucial for:
   - Synchronization (`Pa_GetStreamTime`)
   - Non-blocking I/O (`Pa_GetStream*Available`)
   - Understanding actual latencies (`Pa_GetStreamInfo`)

3. **Host API support** - While not critical for basic use, this becomes important when users need to:
   - Select specific audio subsystems
   - Work around platform-specific issues
   - Access advanced features of specific APIs

These additions would make the Swift wrapper much more complete and suitable for professional audio applications.