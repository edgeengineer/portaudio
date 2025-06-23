import Foundation

// Command-line interface
if CommandLine.arguments.count > 1 {
    // Parse command line arguments
    let args = CommandLine.arguments
    var frequency = 440.0
    var duration = 2.0
    var amplitude: Float = 0.5
    
    var i = 1
    while i < args.count {
        switch args[i] {
        case "-f", "--frequency":
            if i + 1 < args.count, let freq = Double(args[i + 1]) {
                frequency = freq
                i += 1
            }
        case "-d", "--duration":
            if i + 1 < args.count, let dur = Double(args[i + 1]) {
                duration = dur
                i += 1
            }
        case "-a", "--amplitude":
            if i + 1 < args.count, let amp = Float(args[i + 1]) {
                amplitude = min(max(amp, 0.0), 1.0) // Clamp between 0 and 1
                i += 1
            }
        case "-h", "--help":
            print("Usage: swift SineWavePlayer.swift [options]")
            print("Options:")
            print("  -f, --frequency <Hz>    Frequency in Hz (default: 440.0)")
            print("  -d, --duration <sec>    Duration in seconds (default: 2.0)")
            print("  -a, --amplitude <0-1>   Amplitude 0.0 to 1.0 (default: 0.5)")
            print("  -h, --help              Show this help message")
            exit(0)
        default:
            break
        }
        i += 1
    }
    
    do {
        let player = SineWavePlayer(frequency: frequency, amplitude: amplitude)
        try player.play(duration: duration)
    } catch {
        print("Error: \(error)")
        exit(1)
    }
} else {
    // Run the demonstration
    demonstrateSineWavePlayback()
}