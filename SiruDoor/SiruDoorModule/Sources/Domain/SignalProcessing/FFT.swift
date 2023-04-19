//
//  FFT.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/05/28.
//

// https://zenn.dev/moutend/articles/e39f4f162db475bea8c8

import Accelerate
import Foundation

// [Swift] vDSPを利用して高速フーリエ変換する
// https://zenn.dev/moutend/articles/e39f4f162db475bea8c8

// フーリエ変換の虚数部って何だ？
// https://campkougaku.com/2022/01/08/fourier2/

// 離散フーリエ変換を心で理解する
// https://campkougaku.com/2022/01/07/fourier/

// 音の周波数特性を見る
// https://www.geidai.ac.jp/~marui/r_program/spectrum.html

// iOS Accelerateでボイチェン高速化に挑戦したインターン学生の話
// https://note.com/reality_eng/n/n0cd9bd157df3#oounw

/*
 vDSPフレームワークは、デジタル信号処理と大規模アレイ上の汎用演算のための高度に最適化された関数のコレクションを含んでいます。
 デジタル信号処理の面では、例えばフーリエ変換や二次フィルタリング演算を搭載しています。
 演算処理面では、例えば、乗加算などの関数や、和、平均、最大値などの縮小関数などがあります。
 次の一連の画像は、vDSPの機能を説明するものです。
 例えば、vDSP_vtmerg(_:_:_:_:_:_:_:)を使って
 2つの波形（上）を組み合わせてベクトル（下）を生成し、2つの信号間のスムーズな遷移を作成するのに使用することができます。
 */

// 複素数型
struct ComplexFloat {
    var real: Float
    var imaginary: Float

    init(real: Float, imaginary: Float) {
        self.real = real
        self.imaginary = imaginary
    }
}

func FFT(signal: [Float]) -> [ComplexFloat] {
    // vDSP.FFTインスタンスを生成する

    let log2n = vDSP_Length(log2(Float(signal.count)) + 1)
    let fft = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)!

    var signalArray = [Float](signal)

    // UnsafeMutablePointerでメモリーをアロケート、初期化

    let signalImagPtr = UnsafeMutablePointer<Float>.allocate(capacity: signal.count)
    signalImagPtr.initialize(to: 0)

    let outputRealPtr = UnsafeMutablePointer<Float>.allocate(capacity: signal.count)
    outputRealPtr.initialize(to: 0)

    let outputImagPtr = UnsafeMutablePointer<Float>.allocate(capacity: signal.count)
    outputImagPtr.initialize(to: 0)

    // FFTを実行

    signalArray.withUnsafeMutableBufferPointer { signalPtr in
        let input = DSPSplitComplex(realp: signalPtr.baseAddress!, imagp: signalImagPtr)
        var output = DSPSplitComplex(realp: outputRealPtr, imagp: outputImagPtr)

        fft.forward(input: input, output: &output)
    }

    var spectrum = [ComplexFloat](repeating: ComplexFloat(real: 0.0, imaginary: 0.0), count: signal.count)

    for index in 0 ..< signal.count {
        spectrum[index].real = outputRealPtr[index]
        spectrum[index].imaginary = outputImagPtr[index]
    }

    return spectrum
}
