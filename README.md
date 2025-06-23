# PortAudio Swift

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg?style=flat&logo=swift)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg?style=flat&logo=apple)](https://www.apple.com/macos/)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg?style=flat&logo=ios)](https://www.apple.com/ios/)
[![tvOS](https://img.shields.io/badge/tvOS-13.0+-blue.svg?style=flat&logo=appletv)](https://www.apple.com/tv/)
[![watchOS](https://img.shields.io/badge/watchOS-6.0+-blue.svg?style=flat&logo=applewatch)](https://www.apple.com/watch/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%2020.04+-green.svg?style=flat&logo=linux)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg?style=flat)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)

A Swift wrapper for PortAudio, providing cross-platform audio I/O functionality with a modern, type-safe Swift API.

## Why PortAudio Swift?

If you're building audio applications in Swift, you need a reliable, cross-platform audio I/O solution. PortAudio Swift provides:

- **Battle-tested reliability**: Built on PortAudio, used by countless professional audio applications
- **True cross-platform support**: Works seamlessly on macOS, iOS, Linux, and all Apple platforms
- **Modern Swift API**: Type-safe, throwing functions, and Swift-native error handling
- **Low latency**: Direct access to hardware buffers for professional audio applications
- **Flexibility**: Both simple blocking I/O and real-time callback modes
- **No complex dependencies**: Just Swift Package Manager - no need for complex build systems

Whether you're building a DAW, audio analyzer, music player, or IoT audio device, PortAudio Swift gives you the foundation you need.

## Features

- 🎵 **Cross-platform audio I/O** - Works on macOS, iOS, tvOS, watchOS, and Linux
- 🔊 **Device enumeration** - List and query audio input/output devices
- 📡 **Blocking and callback streams** - Support for both blocking I/O and real-time callbacks
- 🎛️ **Multiple sample formats** - Float32, Int32, Int24, Int16, Int8, UInt8
- ⚡ **Low-latency** - Built on PortAudio for professional audio applications
- 🛡️ **Type-safe** - Modern Swift API with comprehensive error handling
- 📱 **Native integration** - Optimized for CoreAudio on Apple platforms, ALSA on Linux

## Installation

### Swift Package Manager

Add PortAudio Swift to your `Package.swift` file:

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
3. Enter the repository URL: `https://github.com/edgeengineer/portaudio.git`
4. Select version 0.0.1 or later
5. Add to your target

## Quick Start

### Initialize PortAudio

```swift
import PortAudio

// Always initialize before use and terminate when done
try PortAudio.initialize()
defer { try? PortAudio.terminate() }
```

### List Audio Devices

```swift
// Get all devices
let devices = PortAudio.getAllDevices()
for device in devices {
    print("\(device.name): \(device.maxInputChannels) in, \(device.maxOutputChannels) out")
}

// Get default devices
if let outputDevice = PortAudio.defaultOutputDevice {
    let info = PortAudio.getDeviceInfo(at: outputDevice)
    print("Default output: \(info?.name ?? "Unknown")")
}
```

### Play Audio (Blocking Mode)

```swift
// Configure output
let outputParams = StreamParameters(
    device: PortAudio.defaultOutputDevice!,
    channelCount: 2,  // Stereo
    sampleFormat: .float32,
    suggestedLatency: 0.05  // 50ms
)

// Create and open stream
let stream = AudioStream()
try stream.open(
    outputParameters: outputParams,
    sampleRate: 44100,
    framesPerBuffer: 256
)

try stream.start()

// Generate and play a sine wave
let buffer = UnsafeMutablePointer<Float>.allocate(capacity: 512)  // 256 frames * 2 channels
defer { buffer.deallocate() }

var phase: Float = 0
let phaseIncrement = 2.0 * Float.pi * 440.0 / 44100.0  // 440 Hz

for _ in 0..<100 {  // Play for ~0.6 seconds
    for frame in 0..<256 {
        let sample = sin(phase)
        buffer[frame * 2] = sample      // Left channel
        buffer[frame * 2 + 1] = sample  // Right channel
        phase += phaseIncrement
    }
    try stream.write(from: buffer, frames: 256)
}

try stream.stop()
try stream.close()
```

### Real-time Audio (Callback Mode)

```swift
// Create stream with callback
var phase: Float = 0
let stream = AudioStream { input, output, frameCount, timeInfo, flags in
    guard let output = AudioBuffer<Float>.from(
        rawPointer: output,
        frameCount: Int(frameCount),
        channelCount: 2
    ) else {
        return .abort
    }
    
    // Generate audio in real-time
    let phaseIncrement = 2.0 * Float.pi * 440.0 / 44100.0
    
    for frame in 0..<output.frameCount {
        let sample = sin(phase) * 0.5  // 50% volume
        output[frame, 0] = sample  // Left channel
        output[frame, 1] = sample  // Right channel
        phase += phaseIncrement
    }
    
    return .continue
}

// Configure and start
try stream.open(
    outputParameters: outputParams,
    sampleRate: 44100,
    framesPerBuffer: 256
)

try stream.start()
Thread.sleep(forTimeInterval: 3.0)  // Play for 3 seconds
try stream.stop()
```

## Running the Examples

The repository includes several example programs demonstrating different features:

### 1. Build the Examples

```bash
swift build
```

### 2. Run Examples

```bash
# Basic device enumeration and info
swift run BasicUsage

# Play MP3 files (macOS/iOS only)
swift run MP3Player Examples/sample.mp3

# Cross-platform sine wave generator
swift run SineWavePlayer

# With custom parameters
swift run SineWavePlayer -f 880 -d 5 -a 0.3
# -f: frequency in Hz (default: 440)
# -d: duration in seconds (default: 2)
# -a: amplitude 0-1 (default: 0.5)
```

### 3. Build Release Versions

```bash
# Build optimized versions
swift build -c release

# Run directly
.build/release/SineWavePlayer -f 440 -d 2
.build/release/MP3Player /path/to/your/audio.mp3
```

### 4. Docker Testing (Linux)

```bash
# Test on Linux with Docker
docker-compose run portaudio-test

# Run examples in Docker
docker-compose run portaudio-example
```

## Platform Support

| Platform | Minimum Version | Audio Backend | Status |
|----------|-----------------|---------------|--------|
| macOS    | 10.15+         | CoreAudio     | ✅ Full Support |
| iOS      | 13.0+          | CoreAudio     | ✅ Full Support |
| tvOS     | 13.0+          | CoreAudio     | ✅ Full Support |
| watchOS  | 6.0+           | CoreAudio     | ✅ Full Support |
| Linux    | Ubuntu 20.04+  | ALSA          | ✅ Full Support |

### Linux Setup

On Linux, install ALSA development libraries:

```bash
# Ubuntu/Debian
sudo apt-get install libasound2-dev

# Fedora/RHEL
sudo dnf install alsa-lib-devel

# Arch Linux
sudo pacman -S alsa-lib
```

## API Documentation

Full API documentation is available through DocC. In Xcode:
1. Build documentation: **Product** → **Build Documentation**
2. Open: **Product** → **Documentation**

Key classes:
- `PortAudio` - Library initialization and device management
- `AudioStream` - Audio I/O streams
- `AudioBuffer` - Type-safe audio buffer access
- `StreamParameters` - Stream configuration
- `DeviceInfo` - Audio device information

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Acknowledgments

- Built on [PortAudio](http://www.portaudio.com/) - the cross-platform audio I/O library
- Thanks to the PortAudio community for decades of audio expertise
- Inspired by the Swift audio community's need for reliable, low-level audio access