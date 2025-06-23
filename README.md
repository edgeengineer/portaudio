# PortAudio Swift

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg?style=flat&logo=swift)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg?style=flat&logo=apple)](https://www.apple.com/macos/)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg?style=flat&logo=ios)](https://www.apple.com/ios/)
[![tvOS](https://img.shields.io/badge/tvOS-13.0+-blue.svg?style=flat&logo=appletv)](https://www.apple.com/tv/)
[![watchOS](https://img.shields.io/badge/watchOS-6.0+-blue.svg?style=flat&logo=applewatch)](https://www.apple.com/watch/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)

A Swift wrapper for PortAudio, providing cross-platform audio I/O functionality with a modern, type-safe Swift API.

## Features

- 🎵 **Cross-platform audio I/O** - Works on macOS, iOS, tvOS, and watchOS
- 🔊 **Device enumeration** - List and query audio input/output devices
- 📡 **Blocking and callback streams** - Support for both blocking I/O and real-time callbacks
- 🎛️ **Multiple sample formats** - Float32, Int32, Int24, Int16, Int8, UInt8
- ⚡ **Low-latency** - Built on PortAudio for professional audio applications
- 🛡️ **Type-safe** - Modern Swift API with comprehensive error handling
- 📱 **Apple ecosystem** - Optimized for CoreAudio on Apple platforms

## Installation

### Swift Package Manager

Add PortAudio Swift to your project using Xcode or by adding it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/edgeengineer/portaudio.git", from: "0.0.1")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["PortAudio"]
    )
]
```

### Xcode Integration

1. Open your Xcode project
2. Go to **File** → **Add Package Dependencies**
3. Enter the repository URL: `https://github.com/yourusername/portaudio-swift.git`
4. Select the version and add to your target

## Quick Start

### Basic Setup

```swift
import PortAudio

do {
    // Initialize PortAudio
    try PortAudio.initialize()
    defer { try? PortAudio.terminate() }
    
    print("PortAudio Version: \(PortAudio.versionText)")
    print("Available devices: \(PortAudio.deviceCount)")
    
} catch {
    print("Failed to initialize PortAudio: \(error)")
}
```

### Device Discovery

```swift
// Get all available devices
let devices = PortAudio.getAllDevices()
for device in devices {
    print("Device \(device.index): \(device.name)")
    print("  Input channels: \(device.maxInputChannels)")
    print("  Output channels: \(device.maxOutputChannels)")
    print("  Default sample rate: \(device.defaultSampleRate) Hz")
}

// Get input/output devices separately
let inputDevices = PortAudio.getInputDevices()
let outputDevices = PortAudio.getOutputDevices()

// Get default devices
if let defaultInput = PortAudio.defaultInputDevice {
    print("Default input device: \(defaultInput)")
}

if let defaultOutput = PortAudio.defaultOutputDevice {
    print("Default output device: \(defaultOutput)")
}
```

### Creating Audio Streams

#### Blocking Stream (Simple I/O)

```swift
guard let defaultOutput = PortAudio.defaultOutputDevice else {
    print("No default output device available")
    return
}

let stream = AudioStream()

let outputParams = StreamParameters(
    device: defaultOutput,
    channelCount: 2,
    sampleFormat: .float32,
    suggestedLatency: 0.05
)

try stream.open(
    outputParameters: outputParams,
    sampleRate: 44100.0,
    framesPerBuffer: 256
)

try stream.start()

// Generate and write audio data
let bufferSize = 256
let buffer = UnsafeMutablePointer<Float>.allocate(capacity: bufferSize * 2) // stereo
defer { buffer.deallocate() }

// Fill buffer with sine wave data
for frame in 0..<bufferSize {
    let sample = sin(Double(frame) * 2.0 * .pi * 440.0 / 44100.0) // 440 Hz sine
    buffer[frame * 2] = Float(sample)     // Left channel
    buffer[frame * 2 + 1] = Float(sample) // Right channel
}

try stream.write(from: buffer, frames: UInt(bufferSize))

try stream.stop()
try stream.close()
```

#### Callback Stream (Real-time)

```swift
let stream = AudioStream { inputBuffer, outputBuffer, frameCount, timeInfo, flags in
    guard let output = outputBuffer?.bindMemory(to: Float.self, capacity: Int(frameCount) * 2) else {
        return .abort
    }
    
    // Generate audio in real-time
    for frame in 0..<Int(frameCount) {
        let sample = sin(Double(frame) * 2.0 * .pi * 440.0 / 44100.0)
        output[frame * 2] = Float(sample)     // Left
        output[frame * 2 + 1] = Float(sample) // Right
    }
    
    return .continue
}

try stream.open(
    outputParameters: outputParams,
    sampleRate: 44100.0,
    framesPerBuffer: 256
)

try stream.start()

// Stream runs in callback mode
Thread.sleep(forTimeInterval: 5.0) // Play for 5 seconds

try stream.stop()
try stream.close()
```

### Recording Audio

```swift
guard let defaultInput = PortAudio.defaultInputDevice else {
    print("No default input device available")
    return
}

let inputParams = StreamParameters(
    device: defaultInput,
    channelCount: 1, // Mono recording
    sampleFormat: .float32,
    suggestedLatency: 0.05
)

let stream = AudioStream()
try stream.open(
    inputParameters: inputParams,
    sampleRate: 44100.0,
    framesPerBuffer: 256
)

try stream.start()

let bufferSize = 256
let buffer = UnsafeMutablePointer<Float>.allocate(capacity: bufferSize)
defer { buffer.deallocate() }

// Record for a few seconds
for _ in 0..<100 { // ~2.3 seconds at 256 samples/buffer, 44.1kHz
    try stream.read(into: buffer, frames: UInt(bufferSize))
    
    // Process recorded audio data
    let rms = sqrt(stride(from: 0, to: bufferSize, by: 1)
        .map { buffer[$0] * buffer[$0] }
        .reduce(0, +) / Float(bufferSize))
    
    print("RMS level: \(rms)")
}

try stream.stop()
try stream.close()
```

## API Reference

### Core Classes

- **`PortAudio`** - Main interface for initialization and device queries
- **`AudioStream`** - Audio stream management for input/output
- **`DeviceInfo`** - Information about audio devices
- **`StreamParameters`** - Configuration for audio streams

### Sample Formats

- `.float32` - 32-bit floating point
- `.int32` - 32-bit signed integer
- `.int24` - 24-bit signed integer
- `.int16` - 16-bit signed integer
- `.int8` - 8-bit signed integer
- `.uint8` - 8-bit unsigned integer

### Error Handling

All PortAudio operations throw `PortAudioError` for comprehensive error handling:

```swift
do {
    try PortAudio.initialize()
    // ... audio operations
} catch PortAudioError.deviceUnavailable {
    print("Audio device is not available")
} catch PortAudioError.invalidSampleRate {
    print("Unsupported sample rate")
} catch {
    print("Other PortAudio error: \(error)")
}
```

## Platform Support

| Platform | Minimum Version | Backend | Status |
|----------|-----------------|---------|--------|
| macOS    | 10.15+         | CoreAudio | ✅ Supported |
| iOS      | 13.0+          | CoreAudio | ✅ Supported |
| tvOS     | 13.0+          | CoreAudio | ✅ Supported |
| watchOS  | 6.0+           | CoreAudio | ✅ Supported |
| Linux    | Ubuntu 20.04+  | ALSA | ✅ Supported |

### Linux Requirements

On Linux systems, you need to install ALSA development libraries:

```bash
# Ubuntu/Debian
sudo apt-get install libasound2-dev

# Fedora/RHEL
sudo dnf install alsa-lib-devel

# Arch Linux
sudo pacman -S alsa-lib
```

## Requirements

- Swift 6.1 or later
- Xcode 15.0 or later (for development)
- Apple platforms with CoreAudio support

## Examples

Check out the `Examples/` directory for complete working examples:

- **BasicUsage.swift** - Device enumeration and basic stream operations
- **MP3Player.swift** - Playing MP3 files using AVFoundation and PortAudio (macOS/iOS only)
- **SineWavePlayer.swift** - Cross-platform sine wave generator (works on Linux)

### Quick Test

First, build the package:

```bash
swift build
```

Then run the examples using Swift's run command:

```bash
# Run the MP3 player with the included sample
swift run --skip-build MP3Player

# Or with a specific file
swift run --skip-build MP3Player Examples/sample.mp3

# Run the sine wave generator
swift run --skip-build SineWavePlayer

# With custom parameters
swift run --skip-build SineWavePlayer -f 880 -d 3 -a 0.3
```

Alternatively, you can create an executable:

```bash
# Build in release mode
swift build -c release

# Run the built executable directly
.build/release/MP3Player Examples/sample.mp3
.build/release/SineWavePlayer -f 440 -d 2
```

### Testing with Docker

Test the package on Linux using Docker:

```bash
# Build and run tests
docker-compose run portaudio-test

# Just build the package
docker-compose run portaudio-build

# Run the basic usage example
docker-compose run portaudio-example

# Or use Docker directly
docker build -t portaudio-swift .
docker run --rm portaudio-swift swift test
```

**Note**: Audio playback in Docker containers requires additional configuration (mounting /dev/snd and running with privileges). The examples will enumerate devices but may not play audio without proper host audio setup.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the excellent [PortAudio](http://www.portaudio.com/) library
- Inspired by the need for modern Swift audio APIs
- Thanks to the PortAudio community for their continued development

---

**Note**: This wrapper focuses on Apple platforms and uses CoreAudio as the backend. For cross-platform development beyond Apple's ecosystem, consider the full PortAudio library with platform-specific backends.