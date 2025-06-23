// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Platform-specific settings
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
let cSettings: [CSetting] = [
    .headerSearchPath("include"),
    .headerSearchPath("portaudio/include"),
    .headerSearchPath("portaudio/src/common"),
    .headerSearchPath("portaudio/src/os/unix"),
    .headerSearchPath("portaudio/src/hostapi/coreaudio"),
    .define("PA_USE_COREAUDIO", to: "1"),
    .define("SIZEOF_SHORT", to: "2"),
    .define("SIZEOF_INT", to: "4"),
    .define("SIZEOF_LONG", to: "8"),
    .define("_DARWIN_C_SOURCE")
]
let linkerSettings: [LinkerSetting] = [
    .linkedFramework("CoreAudio"),
    .linkedFramework("AudioToolbox"),
    .linkedFramework("AudioUnit"),
    .linkedFramework("CoreServices")
]
#elseif os(Linux)
let cSettings: [CSetting] = [
    .headerSearchPath("include"),
    .headerSearchPath("portaudio/include"),
    .headerSearchPath("portaudio/src/common"),
    .headerSearchPath("portaudio/src/os/unix"),
    .headerSearchPath("portaudio/src/hostapi/alsa"),
    .define("PA_USE_ALSA", to: "1"),
    .define("HAVE_CLOCK_GETTIME", to: "1"),
    .define("HAVE_NANOSLEEP", to: "1"),
    .define("SIZEOF_SHORT", to: "2"),
    .define("SIZEOF_INT", to: "4"),
    .define("SIZEOF_LONG", to: "8"),
    .define("_GNU_SOURCE")
]
let linkerSettings: [LinkerSetting] = [
    .linkedLibrary("asound"),
    .linkedLibrary("pthread"),
    .linkedLibrary("m"),
    .linkedLibrary("rt")
]
#else
let cSettings: [CSetting] = []
let linkerSettings: [LinkerSetting] = []
#endif

let package = Package(
    name: "PortAudio",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "PortAudio",
            targets: ["PortAudio"]),
        .executable(
            name: "BasicUsage",
            targets: ["BasicUsage"]),
        .executable(
            name: "MP3Player", 
            targets: ["MP3Player"]),
        .executable(
            name: "SineWavePlayer",
            targets: ["SineWavePlayer"]),
    ],
    targets: [
        .target(
            name: "CPortAudio",
            dependencies: [],
            cSettings: cSettings,
            linkerSettings: linkerSettings
        ),
        .target(
            name: "PortAudio",
            dependencies: ["CPortAudio"]
        ),
        .testTarget(
            name: "PortAudioTests",
            dependencies: ["PortAudio"]
        ),
        .executableTarget(
            name: "BasicUsage",
            dependencies: ["PortAudio"],
            path: "Examples/BasicUsage"
        ),
        .executableTarget(
            name: "MP3Player",
            dependencies: ["PortAudio"],
            path: "Examples/MP3Player",
            resources: [.copy("sample.mp3")]
        ),
        .executableTarget(
            name: "SineWavePlayer",
            dependencies: ["PortAudio"],
            path: "Examples/SineWavePlayer"
        ),
    ]
)