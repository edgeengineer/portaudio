import CPortAudio
import Foundation

public struct AudioBuffer<T> {
    public let data: UnsafeMutablePointer<T>
    public let frameCount: Int
    public let channelCount: Int
    
    public init(data: UnsafeMutablePointer<T>, frameCount: Int, channelCount: Int) {
        self.data = data
        self.frameCount = frameCount
        self.channelCount = channelCount
    }
    
    public subscript(frame: Int, channel: Int) -> T {
        get {
            precondition(frame >= 0 && frame < frameCount, "Frame index out of bounds")
            precondition(channel >= 0 && channel < channelCount, "Channel index out of bounds")
            return data[frame * channelCount + channel]
        }
        set {
            precondition(frame >= 0 && frame < frameCount, "Frame index out of bounds")
            precondition(channel >= 0 && channel < channelCount, "Channel index out of bounds")
            data[frame * channelCount + channel] = newValue
        }
    }
    
    public func frame(at index: Int) -> UnsafeMutablePointer<T> {
        precondition(index >= 0 && index < frameCount, "Frame index out of bounds")
        return data + (index * channelCount)
    }
}

public extension AudioBuffer where T == Float {
    static func from(rawPointer: UnsafeMutableRawPointer?, frameCount: Int, channelCount: Int) -> AudioBuffer<Float>? {
        guard let pointer = rawPointer?.assumingMemoryBound(to: Float.self) else {
            return nil
        }
        return AudioBuffer(data: pointer, frameCount: frameCount, channelCount: channelCount)
    }
}

public extension AudioBuffer where T == Int16 {
    static func from(rawPointer: UnsafeMutableRawPointer?, frameCount: Int, channelCount: Int) -> AudioBuffer<Int16>? {
        guard let pointer = rawPointer?.assumingMemoryBound(to: Int16.self) else {
            return nil
        }
        return AudioBuffer(data: pointer, frameCount: frameCount, channelCount: channelCount)
    }
}

public extension AudioBuffer where T == Int32 {
    static func from(rawPointer: UnsafeMutableRawPointer?, frameCount: Int, channelCount: Int) -> AudioBuffer<Int32>? {
        guard let pointer = rawPointer?.assumingMemoryBound(to: Int32.self) else {
            return nil
        }
        return AudioBuffer(data: pointer, frameCount: frameCount, channelCount: channelCount)
    }
}