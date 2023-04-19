//
//  Resolver.swift
//
//
//  Created by Katsuhiko Terada on 2023/02/06.
//

import Domain
import Foundation

public enum Resolver {
    public static func resolve() {
        NearPeerNotifier.resolve(dependency: NearPeerNotifierResolver())
        NearPeerMonitor.resolve(dependency: NearPeerMonitorResolver())
        SoundAnalyzer.resolve(dependency: SoundAnalyzerResolver())
    }
}
