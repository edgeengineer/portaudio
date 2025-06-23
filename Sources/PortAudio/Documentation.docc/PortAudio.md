# ``PortAudio``

A Swift wrapper for PortAudio, providing cross-platform audio I/O functionality.

## Overview

PortAudio Swift provides a modern, type-safe API for audio input and output on Apple platforms and Linux. Built on top of the battle-tested PortAudio library, it offers low-latency audio processing capabilities for professional audio applications.

### Key Features

- 🎵 **Cross-platform** - Works on macOS, iOS, tvOS, watchOS, and Linux
- 🔊 **Device Management** - Enumerate and query audio devices
- 📡 **Flexible I/O** - Both blocking and callback-based audio streams
- 🎛️ **Multiple Formats** - Support for various sample formats
- ⚡ **Low Latency** - Professional-grade audio performance
- 🛡️ **Type Safety** - Modern Swift API with comprehensive error handling

## Getting Started

Before using any PortAudio functionality, you must initialize the library:

```swift
import PortAudio

do {
    try PortAudio.initialize()
    defer { try? PortAudio.terminate() }
    
    // Your audio code here
    
} catch {
    print("Failed to initialize PortAudio: \(error)")
}
```

## Topics

### Essentials

- ``PortAudio/PortAudio``
- ``PortAudioError``

### Device Management

- ``DeviceInfo``
- ``PortAudio/getAllDevices()``
- ``PortAudio/getInputDevices()``
- ``PortAudio/getOutputDevices()``

### Audio Streams

- ``AudioStream``
- ``StreamParameters``
- ``SampleFormat``

### Stream Callbacks

- ``StreamCallback``
- ``StreamCallbackResult``
- ``StreamCallbackTimeInfo``
- ``StreamCallbackFlags``

### Audio Buffers

- ``AudioBuffer``

## Common Tasks

### Playing Audio

To play audio, create an output stream and write samples to it:

```swift
let outputParams = StreamParameters(
    device: PortAudio.defaultOutputDevice!,
    channelCount: 2,
    sampleFormat: .float32,
    suggestedLatency: 0.05
)

let stream = AudioStream()
try stream.open(
    outputParameters: outputParams,
    sampleRate: 44100,
    framesPerBuffer: 256
)

try stream.start()

// Write audio samples
let buffer = generateAudioSamples()
try stream.write(from: buffer, frames: 256)

try stream.stop()
try stream.close()
```

### Recording Audio

To record audio, create an input stream and read samples from it:

```swift
let inputParams = StreamParameters(
    device: PortAudio.defaultInputDevice!,
    channelCount: 1,
    sampleFormat: .float32,
    suggestedLatency: 0.05
)

let stream = AudioStream()
try stream.open(
    inputParameters: inputParams,
    sampleRate: 44100,
    framesPerBuffer: 256
)

try stream.start()

// Read audio samples
let buffer = UnsafeMutablePointer<Float>.allocate(capacity: 256)
defer { buffer.deallocate() }

try stream.read(into: buffer, frames: 256)

try stream.stop()
try stream.close()
```

### Real-time Processing

For real-time audio processing, use a callback stream:

```swift
let stream = AudioStream { input, output, frameCount, timeInfo, flags in
    guard let output = output?.assumingMemoryBound(to: Float.self) else {
        return .abort
    }
    
    // Process audio in real-time
    for i in 0..<Int(frameCount * 2) { // stereo
        output[i] = generateSample()
    }
    
    return .continue
}

try stream.open(
    outputParameters: outputParams,
    sampleRate: 44100,
    framesPerBuffer: 256
)

try stream.start()
// Stream runs in callback mode
Thread.sleep(forTimeInterval: 5.0)
try stream.stop()
```

## Platform Considerations

### macOS/iOS/tvOS/watchOS
- Uses CoreAudio backend
- Excellent low-latency performance
- Full support for all features

### Linux
- Uses ALSA backend
- Requires ALSA development libraries
- Install with: `sudo apt-get install libasound2-dev`

## Best Practices

1. **Always initialize and terminate**: Use `defer` to ensure cleanup
2. **Check device availability**: Not all devices support all sample rates
3. **Handle errors gracefully**: Audio devices can become unavailable
4. **Use appropriate buffer sizes**: Balance latency vs. stability
5. **Avoid blocking in callbacks**: Keep callback functions fast

## See Also

- [PortAudio Website](http://www.portaudio.com)
- [Examples](https://github.com/yourusername/portaudio-swift/tree/main/Examples)