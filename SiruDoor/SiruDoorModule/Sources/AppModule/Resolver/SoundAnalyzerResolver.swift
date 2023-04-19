//
//  SoundAnalyzerResolver.swift
//
//
//  Created by Katsuhiko Terada on 2023/02/06.
//

import Domain
import Foundation

struct SoundAnalyzerResolver: SoundAnalyzerDependency {
    var soundPeaksArray: [Domain.SoundPeaks] = AppUserDefault.soundPeaksArray
    var fftDisplayParams: FFTDisplayParams = AppUserDefault.fftDisplayParams
}
