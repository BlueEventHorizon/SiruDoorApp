//
//  BPF.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/05/28.
//

// [Swift] vDSPで音声信号をイコライジングする
// https://zenn.dev/moutend/articles/006a949fdd9d176bf878

import Accelerate
import AVFoundation

class FilterParameter {
    let b0: Double
    let b1: Double
    let b2: Double
    let a1: Double
    let a2: Double

    init(_ b0: Double, _ b1: Double, _ b2: Double, _ a1: Double, _ a2: Double) {
        self.b0 = b0
        self.b1 = b1
        self.b2 = b2
        self.a1 = a1
        self.a2 = a2
    }
}

class LowPassFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, q: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let alpha: Double = sin(w0) / (2.0 * q)

        let a0: Double = 1.0 + alpha
        let a1: Double = -2.0 * cos(w0)
        let a2: Double = 1.0 - alpha
        let b0: Double = (1.0 - cos(w0)) / 2.0
        let b1: Double = 1.0 - cos(w0)
        let b2: Double = (1.0 - cos(w0)) / 2.0

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class HighPassFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, q: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let alpha: Double = sin(w0) / (2.0 * q)

        let a0: Double = 1.0 + alpha
        let a1: Double = -2.0 * cos(w0)
        let a2: Double = 1.0 - alpha
        let b0: Double = (1.0 + cos(w0)) / 2.0
        let b1: Double = -1.0 * (1.0 + cos(w0))
        let b2: Double = (1.0 + cos(w0)) / 2.0

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class AllPassFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, q: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let alpha: Double = sin(w0) / (2.0 * q)

        let a0: Double = 1.0 + alpha
        let a1: Double = -2.0 * cos(w0)
        let a2: Double = 1.0 - alpha
        let b0: Double = 1.0 - alpha
        let b1: Double = -2.0 * cos(w0)
        let b2: Double = 1.0 + alpha

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class BandPassFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, width: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let alpha: Double = sin(w0) * sinh(log(2.0) / 2.0 * width * w0 / sin(w0))

        let a0: Double = 1.0 + alpha
        let a1: Double = -2.0 * cos(w0)
        let a2: Double = 1.0 - alpha
        let b0: Double = alpha
        let b1: Double = 0.0
        let b2: Double = -1.0 * alpha

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class BandRejectFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, width: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let alpha: Double = sin(w0) * sinh(log(2.0) / 2.0 * width * w0 / sin(w0))

        let a0: Double = 1.0 + alpha
        let a1: Double = -2.0 * cos(w0)
        let a2: Double = 1.0 - alpha
        let b0: Double = 1.0
        let b1: Double = -2.0 * cos(w0)
        let b2: Double = 1.0

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class LowShelfFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, q: Double, gain: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let a: Double = pow(10.0, gain / 40.0)
        let beta: Double = a.squareRoot() / q

        let a0: Double = (a + 1.0) + (a - 1.0) * cos(w0) + beta * sin(w0)
        let a1: Double = -2.0 * ((a - 1.0) + (a + 1.0) * cos(w0))
        let a2: Double = (a + 1.0) + (a - 1.0) * cos(w0) - beta * sin(w0)
        let b0: Double = a * ((a + 1.0) - (a - 1.0) * cos(w0) + beta * sin(w0))
        let b1: Double = 2.0 * a * ((a - 1.0) - (a + 1.0) * cos(w0))
        let b2: Double = a * ((a + 1.0) - (a - 1.0) * cos(w0) - beta * sin(w0))

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class HighShelfFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, q: Double, gain: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let a: Double = pow(10.0, gain / 40.0)
        let beta: Double = a.squareRoot() / q

        let a0: Double = (a + 1.0) - (a - 1.0) * cos(w0) + beta * sin(w0)
        let a1: Double = 2.0 * ((a - 1.0) - (a + 1.0) * cos(w0))
        let a2: Double = (a + 1.0) - (a - 1.0) * cos(w0) - beta * sin(w0)
        let b0: Double = a * ((a + 1.0) + (a - 1.0) * cos(w0) + beta * sin(w0))
        let b1: Double = -2.0 * a * ((a - 1.0) + (a + 1.0) * cos(w0))
        let b2: Double = a * ((a + 1.0) + (a - 1.0) * cos(w0) - beta * sin(w0))

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

class PeakingFilterParameter: FilterParameter {
    init(sampleRate: Double, frequency: Double, width: Double, gain: Double) {
        let w0: Double = 2.0 * Double.pi * frequency / sampleRate
        let alpha: Double = sin(w0) * sinh(log(2.0) / 2.0 * width * w0 / sin(w0))
        let a: Double = pow(10.0, gain / 40.0)

        let a0: Double = 1.0 + alpha / a
        let a1: Double = -2.0 * cos(w0)
        let a2: Double = 1.0 - alpha / a
        let b0: Double = 1.0 + alpha * a
        let b1: Double = -2.0 * cos(w0)
        let b2: Double = 1.0 - alpha * a

        super.init(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}

// MARK: -

class Filter {
    func readPCMBuffer(url: URL) -> AVAudioPCMBuffer? {
        guard let input = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatInt16, interleaved: false) else {
            return nil
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: AVAudioFrameCount(input.length)) else {
            return nil
        }
        do {
            try input.read(into: buffer)
        } catch {
            return nil
        }

        return buffer
    }

    func writePCMBuffer(url: URL, buffer: AVAudioPCMBuffer) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: buffer.format.settings[AVFormatIDKey] ?? kAudioFormatLinearPCM,
            AVNumberOfChannelsKey: buffer.format.settings[AVNumberOfChannelsKey] ?? 2,
            AVSampleRateKey: buffer.format.settings[AVSampleRateKey] ?? 44_100,
            AVLinearPCMBitDepthKey: buffer.format.settings[AVLinearPCMBitDepthKey] ?? 16
        ]

        do {
            let output = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: false)
            try output.write(from: buffer)
        } catch {
            throw error
        }
    }

    func applyLowPassFilter(from inputPath: String, to outputPath: String) {
        guard let inputBuffer = readPCMBuffer(url: URL(string: inputPath)!) else {
            fatalError("failed to read \(inputPath)")
        }
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: inputBuffer.format, frameCapacity: inputBuffer.frameLength) else {
            fatalError("failed to create a buffer for writing")
        }
        guard let inputInt16ChannelData = inputBuffer.int16ChannelData else {
            fatalError("failed to obtain underlying input buffer")
        }
        guard let outputInt16ChannelData = outputBuffer.int16ChannelData else {
            fatalError("failed to obtain underlying output buffer")
        }

        // Calculate a filter coefficients. (Type = low-pass / Cut off frequency = 440 Hz / Q-value = 1.23)
        let parameter = LowPassFilterParameter(sampleRate: inputBuffer.format.sampleRate, frequency: 220.0, q: 1.23)

        // Because the input might be stereo, create filters for each channels.
        var filters = [vDSP.Biquad](repeating: vDSP.Biquad(coefficients: [parameter.b0, parameter.b1, parameter.b2, parameter.a1, parameter.a2], channelCount: 1, sectionCount: 1, ofType: Float.self)!, count: Int(inputBuffer.format.channelCount))

        for channel in 0 ..< Int(inputBuffer.format.channelCount) {
            let p1: UnsafeMutablePointer<Int16> = inputInt16ChannelData[channel]
            let p2: UnsafeMutablePointer<Int16> = outputInt16ChannelData[channel]

            var signal = [Float](repeating: 0.0, count: Int(inputBuffer.frameLength))

            for i in 0 ..< Int(inputBuffer.frameLength) {
                signal[i] = Float(p1[i]) / 32_767.0
            }

            signal = filters[channel].apply(input: signal)

            for i in 0 ..< Int(inputBuffer.frameLength) {
                if signal[i] < -1.0 {
                    p2[i] = -32_767
                } else if signal[i] > 1.0 {
                    p2[i] = 32_767
                } else {
                    p2[i] = Int16(Int(signal[i] * 32_767))
                }
            }
        }

        outputBuffer.frameLength = inputBuffer.frameLength

        do {
            try writePCMBuffer(url: URL(string: outputPath)!, buffer: outputBuffer)
        } catch {
            fatalError("failed to write \(outputPath)")
        }
    }

    // applyLowPassFilter(from: "file:///tmp/input.wav", to: "file:///tmp/output.wav")
}
