//
//  AppUserDefault.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/23.
//

import Domain
import Foundation
import Infrastructure

public enum UserDefaultKeys: String, CaseIterable {
    case tabIndex
    case soundPeaksArray
    case fftDisplayParams
    case notifierIdentifier
    case monitorIdentifier
}

public actor AppUserDefault {
    @UserDefaultsWrapper(UserDefaultKeys.tabIndex.rawValue, defaultValue: TabItem.recording.rawValue)
    public static var tabIndex: Int

    @UserDefaultsWrapper(UserDefaultKeys.soundPeaksArray.rawValue, defaultValue: [])
    public static var soundPeaksArray: [SoundPeaks]

    @UserDefaultsWrapper(UserDefaultKeys.fftDisplayParams.rawValue, defaultValue: FFTDisplayParams(maxPowerValue: 200, maxFrequency: 2_000))
    public static var fftDisplayParams: FFTDisplayParams

    @UserDefaultsWrapper(UserDefaultKeys.monitorIdentifier.rawValue, defaultValue: UUID().uuidString)
    public static var networkIdentifier: String
}
