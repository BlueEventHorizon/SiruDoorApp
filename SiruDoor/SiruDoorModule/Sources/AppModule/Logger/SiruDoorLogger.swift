//
//  SiruDoorLogger.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/11.
//

import BwLogger
import Foundation

#if targetEnvironment(simulator)
    // swiftlint:disable:next file_types_order prefixed_toplevel_constant
    internal let logger = Logger([PrintLogger()], levels: nil)
#else
    // swiftlint:disable:next file_types_order prefixed_toplevel_constant
    internal let logger = Logger([OSLogger(subsystem: "com.beowulf-tech", category: "App")], levels: nil)
#endif
