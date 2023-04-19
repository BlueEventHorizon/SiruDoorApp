//
//  RealtimeClock.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/06/13.
//

import Foundation

public final class RealtimeClock {
    public typealias NanoSec = UInt64

    public static let nanoSecUnit: Double = 1_000_000_000.0

    public private(set) var times: [UInt64] = [UInt64]()

    public func getTime() -> UInt64 {
        let time = mach_absolute_time()
        return time
    }

    public func storeTime() {
        let time = getTime()
        times.append(time)
    }

    public func elapsed(old: UInt64, new: UInt64) -> NanoSec {
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return 0 }

        let elapsedTime = new - old
        let nanos = elapsedTime * UInt64(info.numer) / UInt64(info.denom)

        return nanos
    }
}
