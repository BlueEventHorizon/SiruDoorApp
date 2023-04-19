//
//  File.swift
//
//
//  Created by Katsuhiko Terada on 2023/02/06.
//

import BwNearPeer
import Domain
import Foundation
import Infrastructure

struct NearPeerNotifierResolver: NearPeerNotifierDependency {
    var serviceType: String { Const.Communication.serviceType }
    var appName: String { InfoPlistKeys.displayName.getAsString() ?? "" }
    var identifier: String { AppUserDefault.networkIdentifier }

    var myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { nil }
    var targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { [.identifier: Const.Communication.monitorIdentifier, .passcode: Const.Communication.passcode] }
}
