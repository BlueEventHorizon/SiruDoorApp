//
//  NearPeerMonitorResolver.swift
//
//
//  Created by Katsuhiko Terada on 2023/02/06.
//

import BwNearPeer
import Domain
import Foundation
import Infrastructure

struct NearPeerMonitorResolver: NearPeerMonitorDependency {
    var serviceType: String { Const.Communication.serviceType }
    var appName: String { InfoPlistKeys.displayName.getAsString() ?? "" }
    var identifier: String { AppUserDefault.networkIdentifier }

    var myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { [.identifier: Const.Communication.monitorIdentifier, .passcode: Const.Communication.passcode] }
    var targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { nil }
}
