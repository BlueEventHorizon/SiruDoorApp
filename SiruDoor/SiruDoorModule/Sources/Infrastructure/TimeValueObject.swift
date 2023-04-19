//
//  TimeValueObject.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation

public struct TimeValueObject {
    public private(set) var nanoseconds: UInt64
    public var seconds: Float {
        // TODO: 誤差ありすぎ
        Float(nanoseconds) / 1_000_000_000
    }

    public init(nanoseconds: UInt64) {
        self.nanoseconds = nanoseconds
    }

    public init(seconds: Float) {
        nanoseconds = UInt64(seconds * 1_000_000_000)
    }
}
