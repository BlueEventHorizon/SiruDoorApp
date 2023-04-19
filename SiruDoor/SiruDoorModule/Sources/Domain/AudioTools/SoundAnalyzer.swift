//
//  SoundAnalyzer.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/05/22.
//

import Foundation

// [vDSP][信号処理]オーディオ・音声分析への道6 高速フーリエ変換 FFT　その2
// https://qiita.com/Talokay/items/bae730bf77775543ec7f

// 周波数分解能はどのように決めるのか？
// https://www.onosokki.co.jp/HP-WK/c_support/faq/fft_common/fft_analys_4.htm
//

public struct FFTValue: Identifiable {
    public var id: Float {
        frequency
    }

    public let frequency: Float
    public let value: Float
}

public enum SoundAnalyzerState {
    case none
    case noReference
    case notMatch
    case match
}

public protocol SoundAnalyzerDependency {
    var soundPeaksArray: [SoundPeaks] {
        get set
    }

    var fftDisplayParams: FFTDisplayParams {
        get set
    }
}

public class SoundAnalyzer: ObservableObject {
    enum AnalyzeMode {
        case rapid
        case complete
    }

    public private(set) static var shared: SoundAnalyzer!
    public typealias Dependency = SoundAnalyzerDependency

    static let realtimeClock = RealtimeClock()

    private var dependency: Dependency

    // 時間軸方向のピークの集合
    @Published public var mFFTDisplayData: [FFTValue] = [FFTValue]()
    @Published public var soundPeaksArrayPublisher: [SoundPeaks] = []
    @Published public private(set) var state: SoundAnalyzerState = .none

    /// リファレンス音（検出すべき音）のパターン
    public private(set) var referencePeaksArray: [SoundPeaks] = []
    /// 検出された音のパターン
    private var currentPeaksArray: [SoundPeaks] = []
    /// FFTの結果が格納される
    private var mFFTData = [FFTValue]()
    /// referenceSoundPeaksArrayを記録する場合は、true
    ///  検出中は、false
    private var recordPattern: Bool = false

    private let soundInput: SoundInput = SoundInput()

    private var detectStartTime: Date?
    private var detectTime: Date?

    private var rapidAnalyze: Bool = true
    private var completeAnalyze: Bool = true

    /// 最短時間で解析を始める時間（遅くなると通知も遅れるので即反応するため）
    public var rapidAnalyzeDuration: TimeInterval = 2.0 // TODO: 設定で変更できるようにする！！
    /// 取得する音圧の最小値
    public var peakValueThreshold: Float = 30 // TODO: 自動で決定できるようにする！！

    public var isAnalyzing: Bool {
        (state == .notMatch || state == .match) && enableAnalyzing
    }

    private var enableAnalyzing: Bool = false

    /// リファレンス音の継続期間（録音時間ではなくピーク検出された期間）
    private var referenceSoundDuration: TimeInterval?

    public static func resolve(dependency: Dependency) {
        shared = SoundAnalyzer(dependency: dependency)
    }

    public static func getInstanceForTest(dependency: Dependency) -> SoundAnalyzer {
        let instance = SoundAnalyzer(dependency: dependency)
        assert(NSClassFromString("XCTest") != nil, "テストのみで呼び出し可能")
        return instance
    }

    private init(dependency: Dependency) {
        self.dependency = dependency

        referencePeaksArray = dependency.soundPeaksArray
        soundPeaksArrayPublisher = referencePeaksArray
        referenceSoundDuration = SoundPeaks.getDuration(of: referencePeaksArray)

        printSoundPeaksArray(referencePeaksArray)

        configureMonitor()
    }

    // MARK: - internal

    private func changeState(_ state: SoundAnalyzerState) {
        self.state = state
    }

    private func configureMonitor() {
        soundInput.delegate = self

        soundInput.startAudioCapture()
    }

    public func startMonitor() {
        enableAnalyzing = true

        if !referencePeaksArray.isEmpty {
            changeState(.notMatch)
        }
    }

    public func stopMonitor() {
        enableAnalyzing = false
    }

    public func startRecordPattern() {
        referencePeaksArray = []
        dependency.soundPeaksArray = referencePeaksArray

        changeState(.noReference)

        recordPattern = true
    }

    public func endRecordPattern() {
        recordPattern = false

        if referencePeaksArray.isEmpty {
            changeState(.noReference)
        } else {
            changeState(.notMatch)
        }

        dependency.soundPeaksArray = referencePeaksArray
        soundPeaksArrayPublisher = referencePeaksArray
        referenceSoundDuration = SoundPeaks.getDuration(of: referencePeaksArray)

        printSoundPeaksArray(referencePeaksArray)
    }

    public func deletePattern() {
        referencePeaksArray = []
        dependency.soundPeaksArray = referencePeaksArray

        changeState(.noReference)
    }

    // MARK: - private

    private func reset() {
        detectTime = nil
        detectStartTime = nil
        currentPeaksArray = []

        rapidAnalyze = true
        completeAnalyze = true
    }

    private func analyze(soundPeaksArray: [SoundPeaks], mode: AnalyzeMode) {
        guard !soundPeaksArray.isEmpty, !referencePeaksArray.isEmpty else { return }

        // logger.info("解析開始")

        let referenceStatics = SoundPeaks.getStatics(of: referencePeaksArray)
        let currentStatics = SoundPeaks.getStatics(of: soundPeaksArray)

        let (_, largestSoundPeak) = referenceStatics.getLargestSoundPeakWithIndex()
        let value = currentStatics.getValueOfFrequency(largestSoundPeak.frequency)

        let (_, secondLargestSoundPeak) = referenceStatics.getLargestSoundPeakWithIndex(without: [largestSoundPeak.frequency])
        let secondValue = currentStatics.getValueOfFrequency(secondLargestSoundPeak.frequency)

        if value != nil, secondValue != nil {
            // logger.info("⭕️")
            changeState(.match)
        }
    }

    private func analyze(soundPeaksArray: [SoundPeaks]) {
        guard isAnalyzing else {
            return
        }

        // 所定の期間に音が集まらなかった場合かどうか判定
        if let currentArrayDuration = SoundPeaks.getDuration(of: soundPeaksArray), let referenceSoundDuration = referenceSoundDuration, !recordPattern {
            let referenceSoundDuration80 = referenceSoundDuration * 0.8
            let newShortestJudgeDuration: TimeInterval = min(rapidAnalyzeDuration, referenceSoundDuration * 0.5)

            if rapidAnalyze, currentArrayDuration > newShortestJudgeDuration {
                rapidAnalyze = false
                // 一度目の早期解析
                analyze(soundPeaksArray: soundPeaksArray, mode: .rapid)
            }

            if completeAnalyze, currentArrayDuration > referenceSoundDuration80, referenceSoundDuration80 > newShortestJudgeDuration {
                completeAnalyze = false
                // 二度目の完全解析
                analyze(soundPeaksArray: soundPeaksArray, mode: .complete)
            }
        }
    }

    private func printSoundPeaks(_ soundPeaks: SoundPeaks) {
        guard !soundPeaks.peaks.isEmpty else { return }

        let timeString = String(format: "%.4f", soundPeaks.time)

        print("Time: \(timeString) -- ", terminator: "")
        var sep = ""
        for peak in soundPeaks.peaks {
            let frequencyString = String(format: "%.1f", peak.frequency)
            let valueString = String(format: "%.1f", peak.value)

            print("\(sep)\(frequencyString) (\(valueString))", terminator: "")
            sep = ", "
        }
        print("")
    }

    private func printSoundPeaksArray(_ soundPeaksArray: [SoundPeaks]) {
        guard !soundPeaksArray.isEmpty else {
            // logger.info("- 記録された音パターンはありません -")
            return
        }
        // logger.info("- 記録された音パターン (START) -------------------------------")
        for soundPeaks in soundPeaksArray {
            printSoundPeaks(soundPeaks)
        }
        // logger.info("- 記録された音パターン (END) -------------------------------")
    }

    /// FFTを実行する
    private func setFFTValues(_ fft: [ComplexFloat], samplingFrequency: Float = 48_000.0) -> [FFTValue] {
        let max = fft.count / 2

        if mFFTData.isEmpty {
            mFFTData = [FFTValue](repeating: FFTValue(frequency: 0, value: 0), count: max + 1)
        }

        let frequencyStep = samplingFrequency / Float(fft.count)

        for (index, value) in fft.enumerated() {
            if index > max {
                break
            }

            // let oldPower = mFFTData[index].value
            let power = sqrt(pow(value.real, 2) + pow(value.imaginary, 2))

            let frequency = Float(index) * frequencyStep

            mFFTData[index] = .init(frequency: round(frequency), value: power)
        }

        return mFFTData
    }

    /// 表示用にリサンプリングする
    private func displaySoundFeatures() {
        let maxPowerValue = dependency.fftDisplayParams.maxPowerValue
        var temp = [FFTValue]()
        for value in mFFTData {
            if value.frequency > dependency.fftDisplayParams.maxFrequency {
                break
            }

            let newValue = FFTValue(frequency: round(value.frequency), value: value.value > maxPowerValue ? maxPowerValue : value.value)
            temp.append(newValue)
        }

        DispatchQueue.main.async {
            self.mFFTDisplayData = temp
        }
    }
}

// MARK: - RecordAudioDelegate

// RecordAudioから音データをリアルタイムで取得し、FFTを使って特徴量を取り出す

extension SoundAnalyzer: SoundInputDelegate {
    func sendSoundData(_ sender: SoundInput, buffer: StereoSignalBuffer) {
        // Self.realtimeClock.storeTime()

        buffer.execHammingWindowToLeft()
        let leftSignalFFT = FFT(signal: buffer.leftSignal)
        let signalFFT = setFFTValues(leftSignalFFT)

        // let nanos = Self.realtimeClock.elapsed(old: Self.realtimeClock.times.last!, new: Self.realtimeClock.getTime()) / 1000_000 // msec
        // print("\(nanos)msec")

        let soundPeaks: SoundPeaks
        if let detectStartTime = detectStartTime {
            soundPeaks = SoundPeaks(time: Date().timeIntervalSince1970 - detectStartTime.timeIntervalSince1970, peakValueThreshold: peakValueThreshold)
        } else {
            soundPeaks = SoundPeaks(time: 0, peakValueThreshold: peakValueThreshold)
        }

        let max = signalFFT.count
        for index in 0 ..< max {
            let val = signalFFT[index]

            soundPeaks.setBiggerValues(value: val.value, frequency: val.frequency)
        }

        // --- For Debug ---
        printSoundPeaks(soundPeaks)
        // --- For Debug ---

        if !soundPeaks.peaks.isEmpty {
            // 検出された今の時間
            detectTime = Date()

            if recordPattern {
                if referencePeaksArray.isEmpty {
                    // 最初に検出された時間
                    detectStartTime = detectTime
                }
                referencePeaksArray.append(soundPeaks)
            } else {
                if isAnalyzing {
                    if currentPeaksArray.isEmpty {
                        // 最初に検出された時間
                        detectStartTime = detectTime
                    }
                    currentPeaksArray.append(soundPeaks)
                }
            }
        }

        analyze(soundPeaksArray: currentPeaksArray)

        // 最後に音が検出された時間から、2秒間何も入力がなければリセットする
        if let detectTime = detectTime, detectStartTime != nil {
            if Date().timeIntervalSince(detectTime) > 2.0 {
                if recordPattern {
                    // 音を記録する
                    endRecordPattern()
                    reset()
                } else {
                    if isAnalyzing {
                        // 音を判定する
                        reset()
                        changeState(.notMatch)
                    }
                }
            }
        }

        displaySoundFeatures()
    }
}

// E: 82Hz
// A: 110Hz
// D: 146Hz
// G: 196Hz
// B: 246Hz
// C: 261Hz
// E: 329Hz
