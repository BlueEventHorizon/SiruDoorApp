//
//  FFTDisplayParams.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/09/02.
//

import Foundation

public struct FFTDisplayParams: Codable {
    public let maxPowerValue: Float
    public var maxFrequency: Float

    public init(maxPowerValue: Float, maxFrequency: Float) {
        self.maxPowerValue = maxPowerValue
        self.maxFrequency = maxFrequency
    }
}
