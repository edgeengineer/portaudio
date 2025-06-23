import Foundation

// Command-line entry point
if CommandLine.arguments.count > 1 {
    // If a file path is provided as argument
    let mp3Path = CommandLine.arguments[1]
    let mp3URL = URL(fileURLWithPath: mp3Path)
    
    do {
        let player = MP3Player()
        try player.play(mp3URL: mp3URL)
        
        // Keep the program running until playback completes
        RunLoop.main.run()
    } catch {
        print("Error: \(error)")
        exit(1)
    }
} else {
    // Run the demonstration
    demonstrateMP3Playback()
}