//
//  SoundPeaks.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/13.
//

import Foundation

// 個別の音のピーク情報
public struct SoundPeak: Codable {
    let frequency: Float
    var value: Float

    init(frequency: Float, value: Float) {
        self.frequency = frequency
        self.value = value
    }

    mutating func updateValue(_ value: Float) {
        self.value = value
    }
}

extension SoundPeak {
    static func + (lhs: SoundPeak, rhs: SoundPeak) -> SoundPeak? {
        guard lhs.frequency == rhs.frequency else { return nil }
        return SoundPeak(frequency: lhs.frequency, value: lhs.value + rhs.value)
    }
}

// 複数の周波数に現れたピークの集合
public class SoundPeaks: Codable {
    let time: TimeInterval
    let maxSoundPeaks: Int
    var minValue: Float = 1_000_000_000 // 最大値のみたて
    var peaks: [SoundPeak] = [] // 配列は最大でmaxSoundPeaks
    private let peakValueThreshold: Float

    init(time: TimeInterval, peakValueThreshold: Float, maxSoundPeaks: Int = 3) {
        self.time = time
        self.peakValueThreshold = peakValueThreshold
        self.maxSoundPeaks = maxSoundPeaks
    }

    func setBiggerValues(value: Float, frequency: Float) {
        guard value > peakValueThreshold else { return }

        if peaks.count < maxSoundPeaks {
            peaks.append(SoundPeak(frequency: frequency, value: value))
            if minValue > value {
                minValue = value
            }
        } else {
            guard minValue < value else { return }

            let (smallestIndex, _) = getSmallestSoundPeakWithIndex()
            if let smallestIndex = smallestIndex {
                // 最小値のSoundPeakを削除
                peaks.remove(at: smallestIndex)

                // 新しいSoundPeakを追加
                peaks.append(SoundPeak(frequency: frequency, value: value))
            }

            // 最小値の更新
            minValue = 1_000_000_000
            for peak in peaks where peak.value < minValue {
                minValue = peak.value
            }
        }
    }

    func append(value: Float, frequency: Float) {
        if peaks.count < maxSoundPeaks {
            peaks.append(SoundPeak(frequency: frequency, value: value))
        } else {
            fatalError("分析用のメモリーをオーバーしました")
        }
    }

    @discardableResult
    func replace(value: Float, frequency: Float) -> Bool {
        for (index, peak) in peaks.enumerated() where peak.frequency == frequency {
            peaks[index].value = value
            return true
        }
        return false
    }

    func getValueOfFrequency(_ frequency: Float) -> Float? {
        for peak in peaks where peak.frequency == frequency {
            return peak.value
        }
        return nil
    }

    /// 最小値となるSoundPeakと、indexを返す
    /// - Returns: オプショナルなので⚠️
    func getSmallestSoundPeakWithIndex() -> (Int?, SoundPeak?) {
        var resultIndex: Int?
        var resultPeak: SoundPeak?
        var value: Float = 1_000_000_000

        for (index, peak) in peaks.enumerated() where peak.value < value {
            value = peak.value
            resultIndex = index
            resultPeak = peak
        }
        return (resultIndex, resultPeak)
    }

    /// 最大値となるSoundPeakと、indexを返す
    /// - Parameter frequencies: ただしこの除外周波数が指定されている場合は、それを除く
    /// - Returns: 最大値となるSoundPeakと、index
    func getLargestSoundPeakWithIndex(without frequencies: [Float]? = nil) -> (Int, SoundPeak) {
        var resultIndex: Int = 0
        var resultPeak = SoundPeak(frequency: 0, value: 0)

        for (index, peak) in peaks.enumerated() where peak.value > resultPeak.value {
            if let frequencies = frequencies, frequencies.contains(peak.frequency) {
                // 指定された周波数を含んでいる場合は、飛ばす
                continue
            }

            resultIndex = index
            resultPeak = peak
        }
        return (resultIndex, resultPeak)
    }

    static func getDuration(of soundPeaksArray: [SoundPeaks]) -> TimeInterval? {
        guard let firstTime = soundPeaksArray.first?.time, let lastTime = soundPeaksArray.last?.time, firstTime != lastTime else {
            return nil
        }

        let timeInterval = lastTime - firstTime
        return timeInterval
    }

    static func getNewFrequency(of soundPeaksArray: [SoundPeaks], target: SoundPeaks) -> Float? {
        for soundPeaks in soundPeaksArray {
            for soundPeak in soundPeaks.peaks where target.getValueOfFrequency(soundPeak.frequency) == nil {
                return soundPeak.frequency
            }
        }
        return nil
    }

    static func getStatics(of soundPeaksArray: [SoundPeaks]) -> SoundPeaks {
        let first = soundPeaksArray.first?.time ?? 0
        let last = soundPeaksArray.last?.time ?? 0

        let resultSoundPeaks: SoundPeaks = SoundPeaks(time: last - first, peakValueThreshold: 0, maxSoundPeaks: 100)

        while true {
            if let frequency = getNewFrequency(of: soundPeaksArray, target: resultSoundPeaks) {
                for soundPeaks in soundPeaksArray {
                    if let soundPeak = soundPeaks.peaks.first( where: { $0.frequency == frequency }) {
                        if let value = resultSoundPeaks.getValueOfFrequency(frequency) {
                            resultSoundPeaks.replace(value: soundPeak.value + value, frequency: frequency)
                        } else {
                            resultSoundPeaks.append(value: soundPeak.value, frequency: frequency)
                        }
                    }
//                    for soundPeak in soundPeaks.peaks {
//                        if soundPeak.frequency == frequency {
//                            if let value = resultSoundPeaks.getValueOfFrequency(frequency) {
//                                resultSoundPeaks.replace(value: soundPeak.value + value, frequency: frequency)
//                            } else {
//                                resultSoundPeaks.append(value: soundPeak.value, frequency: frequency)
//                            }
//                            break
//                        }
//                    }
                }
            } else {
                break
            }
        }

        return resultSoundPeaks
    }
}
