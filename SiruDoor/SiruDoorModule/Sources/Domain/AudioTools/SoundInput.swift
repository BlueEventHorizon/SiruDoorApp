//
//  SoundInput.swift
//  SiluDoorApp
//
//  Created by Katsuhiko Terada on 2022/05/04.
//  Originally from https://gist.github.com/hotpaw2/ba815fc23b5d642705f2b1dedfaf0107

//
//  RecordAudio.swift
//
//  This is a Swift class (updated for Swift 5)
//    that uses the iOS RemoteIO Audio Unit
//    to record audio input samples,
//  (should be instantiated as a singleton object.)
//
//  Created by Ronald Nicholson on 10/21/16.
//  Copyright © 2017,2019 HotPaw Productions. All rights reserved.
//  http://www.nicholson.com/rhn/
//  Distribution permission: BSD 2-clause license
//

import AudioUnit
import AVFoundation
import Foundation

final class StereoSignalBuffer {
    // https://github.com/BlueEventHorizon/SiruDoor/issues/2
    static let samplingNumber = 8_192 // 4_096
    var leftSignal: [Float] = [Float](repeating: 0, count: StereoSignalBuffer.samplingNumber)
    var rightSignal: [Float] = [Float](repeating: 0, count: StereoSignalBuffer.samplingNumber)
    var index: Int = 0
    var sampleRate: Double = 44_100.0
    var tag: Int

    init(tag: Int) {
        self.tag = tag
    }

    func execHammingWindowToLeft() {
        for (index, signal) in leftSignal.enumerated() {
            let rad = Float(index) / Float(StereoSignalBuffer.samplingNumber)
            let coefficient: Float = 0.54 - 0.46 * cos(2 * Float.pi * rad)
            leftSignal[index] = signal * coefficient
        }
    }
}

protocol SoundInputDelegate: AnyObject {
    func sendSoundData(_ sender: SoundInput, buffer: StereoSignalBuffer)
}

final class SoundInput: NSObject, SoundControlProtocol {
    static let samplingNumber: Double = 8_192 // 4_096

    private var audioUnit: AudioUnit?

    private var micPermission = false
    private var isSessionActive = false
    private var isRecording = false

    private var sampleRate: Double = 44_100.0 // default audio sample rate

    private var interrupted = false // for restart from audio interruption notification

    static var numberOfChannels: Int = 2 // 2 channel stereo

    private let outputBus: UInt32 = 0 // スピーカなど
    private let inputBus: UInt32 = 1 // マイクなど

    weak var delegate: SoundInputDelegate?
    var audioLevel: Float = 0.0
    var osErr: OSStatus = noErr

    // ------------------------------------------------------------------------------------------
    // MARK: - func
    // ------------------------------------------------------------------------------------------

    /// 入力開始
    func startAudioCapture() {
        currentBuffer = nextBuffer()

        // 1) マイク入力の許可リクエスト
        requestRecordPermission { permitted in
            if permitted {
                Task.detached {
                    await self.startCapture()
                }
            } else {
                self.showAlert()
            }
        }
    }

    /// 入力停止
    func stopAudioCapture() {
        guard let audioUnit = audioUnit else {
            return
        }
        AudioUnitUninitialize(audioUnit)
        isRecording = false
    }

    private func showAlert() {}

    // ------------------------------------------------------------------------------------------
    // MARK: - AudioSession / AudioUnit
    // ------------------------------------------------------------------------------------------

    // 2) AudioSessionを開始、AudioUnitを設定
    @MainActor
    private func startCapture() {
        if isRecording { return }

        if !isSessionActive {
            isSessionActive = startAudioSession()
        }

        if isSessionActive {
            startAudioUnit()
        }
    }

    private func requestRecordPermission(handler: @escaping ((Bool) -> Void)) {
        let audioSession = AVAudioSession.sharedInstance()

        if micPermission {
            handler(true)
        } else {
            audioSession.requestRecordPermission { (granted: Bool) in
                self.micPermission = granted
                handler(granted)
            }
        }
    }

    private func startAudioSession() -> Bool {
        // set and activate Audio Session
        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(AVAudioSession.Category.record)

            // ハードウェアのサンプリングレートを取得
            let hardwareSamplingRate = audioSession.sampleRate

            let preferredSampleRate: Double

            switch hardwareSamplingRate {
                case 48_000.0:
                    preferredSampleRate = 48_000.0

                default:
                    preferredSampleRate = 44_100.0
            }

            /*
              ハードウェアのサンプリングレートは、44.1KHzの場合と、48KHzの場合があります。
              44.1KHzの場合に、4096点のサンプリングに要する時間は、0.093秒
              48KHzの場合に、4096点のサンプリングに要する時間は、0.086秒
              となります。
             */
            let preferredIOBufferDuration: TimeInterval = 1.0 / preferredSampleRate * SoundInput.samplingNumber

            // 入力および出力オーディオサンプルレートの変更を要求
            try audioSession.setPreferredSampleRate(preferredSampleRate)
            // I/O バッファの持続時間の変更を要求
            try audioSession.setPreferredIOBufferDuration(preferredIOBufferDuration)

            sampleRate = audioSession.sampleRate

            // logger.debug("sampleRate = \(audioSession.sampleRate)")
            // logger.debug("ioBufferDuration = \(audioSession.ioBufferDuration)")

            // 割り込みの対応
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: nil,
                using: myAudioSessionInterruptionHandler
            )

            try audioSession.setActive(true)
            return true
        } catch /* let error as NSError */ {
            // handle error here
        }
        return false
    }

    private func startAudioUnit() {
        if audioUnit == nil {
            setupAudioUnit()
        }
        guard let au = audioUnit
        else { return }

        osErr = AudioUnitInitialize(au)

        if osErr != noErr { return }
        osErr = AudioOutputUnitStart(au)

        if osErr == noErr {
            isRecording = true
        }
    }

    private func setupAudioUnit() {
        // kAudioUnitType_Output
        // kAudioUnitSubType_RemoteIO
        // は、ハードウェアを意味している
        var componentDesc: AudioComponentDescription
            = AudioComponentDescription(
                componentType: OSType(kAudioUnitType_Output),
                componentSubType: OSType(kAudioUnitSubType_RemoteIO),
                componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                componentFlags: UInt32(0),
                componentFlagsMask: UInt32(0)
            )

        // 指定されたオーディオコンポーネントの次に、AudioComponentDescription 構造体に合致するコンポーネントを検索する
        // ここでは、最初に見つかったコンポーネントを返す
        let component: AudioComponent! = AudioComponentFindNext(nil, &componentDesc)

        // 新しいオーディオコンポーネントを作成
        var tempAudioUnit: AudioUnit?
        osErr = AudioComponentInstanceNew(component, &tempAudioUnit)
        audioUnit = tempAudioUnit

        guard let audioUnit = audioUnit else { return }

        var enableFlag: UInt32 = 1

        // マイク入力を有効にする
        // I/Oユニットのバス1は、マイクからの録音など、入力ハードウェアに接続します。
        // 入力はデフォルトで無効になっています。
        // 入力を有効にするには、次のようにバス1の入力スコープを有効にする必要があります。
        // https://developer.apple.com/documentation/audiounit/audio_unit_properties/1534116-i_o_audio_unit_properties
        osErr = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     inputBus,
                                     &enableFlag,
                                     UInt32(MemoryLayout<UInt32>.size))

        // オーディオフォーマットの設定
        // サンプリングレート、データフォーマットとしてリニアPCM、Float型
        var streamFormatDesc: AudioStreamBasicDescription = AudioStreamBasicDescription(
            mSampleRate: Double(sampleRate),
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked,
            mBytesPerPacket: UInt32(SoundInput.numberOfChannels * MemoryLayout<UInt32>.size),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(SoundInput.numberOfChannels * MemoryLayout<UInt32>.size),
            mChannelsPerFrame: UInt32(SoundInput.numberOfChannels),
            mBitsPerChannel: UInt32(8 * (MemoryLayout<UInt32>.size)),
            mReserved: UInt32(0)
        )

        /// 入力フォーマットを設定
        osErr = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Input,
                                     outputBus,
                                     &streamFormatDesc,
                                     UInt32(MemoryLayout<AudioStreamBasicDescription>.size))

        /// 出力フォーマットを設定
        osErr = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Output,
                                     inputBus,
                                     &streamFormatDesc,
                                     UInt32(MemoryLayout<AudioStreamBasicDescription>.size))

        /// コールバック
        var inputCallbackStruct
            = AURenderCallbackStruct(inputProc: renderCallback,
                                     inputProcRefCon:
                                     UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        /// Callbackを設定
        osErr = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_SetInputCallback,
                                     // kAudioUnitScope_Global,
                                     kAudioUnitScope_Input,
                                     inputBus,
                                     &inputCallbackStruct,
                                     UInt32(MemoryLayout<AURenderCallbackStruct>.size))

        /// Bufferを確保
        osErr = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_ShouldAllocateBuffer,
                                     kAudioUnitScope_Output,
                                     inputBus,
                                     &enableFlag,
                                     UInt32(MemoryLayout<UInt32>.size))
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - コールバック
    // ------------------------------------------------------------------------------------------

    private var bufferIndex = 0
    private var maxBufferIndex = 1

    lazy var circularBuffers: [StereoSignalBuffer] = {
        var buffers = [StereoSignalBuffer]()
        (0 ..< 2).forEach { buffers.append(StereoSignalBuffer(tag: $0)) }
        return buffers
    }()

    private func nextBuffer() -> StereoSignalBuffer {
        // print(#function)

        let next = circularBuffers[bufferIndex]
        next.index = 0

        bufferIndex += 1
        if bufferIndex > maxBufferIndex {
            bufferIndex = 0
        }

        return next
    }

    var currentBuffer: StereoSignalBuffer!

    /// 音を取得するコールバック関数
    let renderCallback: AURenderCallback = {
        inRefCon, // AudioUnitからのデータ
            ioActionFlags, // AudioUnitRenderActionFlags 処理フラグ
            inTimeStamp, // AudioTimeStamp タイムスタンプ
            inBusNumber, // UInt32 バス番号
            frameCount, // UInt32 フレーム数
            _ // AudioBufferList
            -> OSStatus in

        let audioObject: SoundInput = unsafeBitCast(inRefCon, to: SoundInput.self)
        var err: OSStatus = noErr

        // set mData to nil, AudioUnitRender() should be allocating buffers
        var bufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: UInt32(numberOfChannels),
                mDataByteSize: 16,
                mData: nil
            )
        )

        if let au = audioObject.audioUnit {
            err = AudioUnitRender(au,
                                  ioActionFlags,
                                  inTimeStamp,
                                  inBusNumber,
                                  frameCount,
                                  &bufferList)
        }

        audioObject.processMicrophoneBuffer(inputDataList: &bufferList, frameCount: UInt32(frameCount))

        return 0
    }

    /// 音を格納したバッファーを解析
    func processMicrophoneBuffer( // process RemoteIO Buffer from mic input
        inputDataList: UnsafeMutablePointer<AudioBufferList>,
        frameCount: UInt32
    ) {
        let inputDataPtr = UnsafeMutableAudioBufferListPointer(inputDataList)
        let mBuffers: AudioBuffer = inputDataPtr[0]
        let count = Int(frameCount)

        // Microphone Input Analysis
        let bufferPointer = UnsafeMutableRawPointer(mBuffers.mData)
        if let buffPtr = bufferPointer {
            let dataArray: UnsafeMutablePointer<Float> = buffPtr.assumingMemoryBound(to: Float.self)

            let max = StereoSignalBuffer.samplingNumber
            for frame in 0 ..< count {
                let step = frame << 1
                let leftChannel = Float(dataArray[step]) // copy left  channel sample
                let rightChannel = Float(dataArray[step + 1]) // copy right channel sample

                currentBuffer.leftSignal[currentBuffer.index] = leftChannel
                currentBuffer.rightSignal[currentBuffer.index] = rightChannel
                currentBuffer.index += 1

                if currentBuffer.index >= max {
                    delegate?.sendSoundData(self, buffer: currentBuffer)
                    // ダブルバッファーにして別のバッファにスイッチ

                    currentBuffer = nextBuffer()
                }
            }
        }
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - 割り込みの対応
    // ------------------------------------------------------------------------------------------

    // Responding to Audio Session Interruptions
    // https://developer.apple.com/documentation/avfaudio/avaudiosession/responding_to_audio_session_interruptions
    func myAudioSessionInterruptionHandler(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        if type == AVAudioSession.InterruptionType.began {
            // システムはアプリのオーディオセッションの中断処理

            if isRecording {
                stopAudioCapture()
                isRecording = false
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setActive(false)
                    isSessionActive = false
                } catch {}
                interrupted = true
            }
        } else if type == AVAudioSession.InterruptionType.ended {
            if interrupted {
                // オーディオセッションのResume

                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }

                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // An interruption ended. Resume playback.
                } else {
                    // An interruption ended. Don't resume playback.
                }
            }
        }
    }
}
