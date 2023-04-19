//
//  NearPeerMonitor.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/11.
//

import BwNearPeer
import Combine
import Foundation
import Infrastructure
#if canImport(UIKit)
    import UIKit.UIDevice
#endif

public protocol NearPeerMonitorDependency {
    /// InfoPlistに記述が必要
    var serviceType: String { get }

    // Info.plistで記述される
    var appName: String { get }

    /// 永続的かつユニークである必要がある
    var identifier: String { get }

    var myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { get }

    var targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { get }
}

public class NearPeerMonitor: ObservableObject {
    public typealias Dependency = NearPeerMonitorDependency

    public private(set) static var shared: NearPeerMonitor!

    private let dependency: Dependency

    @Published var peerNames: [PeerIdentifier] = []
    @Published var receivedText: String = "まだ受信していません"

    private let nearPeer: NearPeer

    /// 複数の「しるドア」の識別子を格納する
    private let peers = StructHolder()

    private var sendCounter: Int = 0

    public static func resolve(dependency: Dependency) {
        shared = NearPeerMonitor(dependency: dependency)
    }

    public static func getInstanceForTest(dependency: Dependency) -> NearPeerMonitor {
        let instance = NearPeerMonitor(dependency: dependency)
        assert(NSClassFromString("XCTest") != nil, "テストのみで呼び出し可能")
        return instance
    }

    private init(dependency: Dependency) {
        self.dependency = dependency

        // 一度に接続できる「しるドアモニター」は１つだけ
        nearPeer = NearPeer(maxPeers: 1)
    }

    public func start() {
        NotificationUsecase.default.auth()

        nearPeer.start(serviceType: dependency.serviceType,
                       displayName: "\(dependency.appName).\(dependency.identifier)",
                       myDiscoveryInfo: dependency.myDiscoveryInfo,
                       targetDiscoveryInfo: dependency.targetDiscoveryInfo)

        nearPeer.onConnected { peer in
            // logger.info("🔵 [MON] \(peer.displayName) Connected", instance: self)
            // TODO: 切断された時の処理を追加すること

            let peerComponents = peer.displayName.components(separatedBy: ".")

            if let displayName = peerComponents.first, let uuidString = peerComponents.last, let uuid = UUID(uuidString: uuidString) {
                self.peers.set(PeerIdentifier(id: uuid, displayName: displayName))
                self.peerNames = self.peers.map {
                    $0 as! PeerIdentifier
                }

                // logger.info("🟡 [MON] peerName | \(displayName), peerIdentifier = \(uuidString)", instance: self)
            }
        }

        nearPeer.onDisconnect { peer in
            Task {
                await MainActor.run {
                    // logger.warning("🔴 [MON] \(peer) is disconnected")

                    let peerComponents = peer.displayName.components(separatedBy: ".")

                    if let uuidString = peerComponents.last, let uuid = UUID(uuidString: uuidString) {
                        self.peers.remove(identifier: uuid)
                        self.peerNames = self.peers.map {
                            $0 as! PeerIdentifier
                        }
                    }
                }
            }
        }

        nearPeer.onReceived { _, data in
            Task {
                await MainActor.run {
                    // logger.info("🟢 [MON] Received", instance: self)

                    guard let data = data else {
                        // logger.error("データがありません")
                        return
                    }

                    if let content = try? JSONDecoder().decode(SimpleNotificationContent.self, from: data) {
                        NotificationUsecase.default.present(content: content)
                        self.receivedText = content.body
                    } else if let text = try? JSONDecoder().decode(String.self, from: data) {
                        self.receivedText = text
                    } else {
                        // logger.error("decode失敗")
                    }
                }
            }
        }
    }

    public func stop() {
        nearPeer.stop()
    }

    public func resume() {
        nearPeer.resume()
    }

    public func suspend() {
        nearPeer.suspend()
    }

    public func send(text: String) {
        // logger.entered(self)

        let content = SimpleNotificationContent(title: dependency.appName, subtitle: "🛎", body: text, image: nil)

        if let encodedContent: Data = try? JSONEncoder().encode(content) {
            nearPeer.send(encodedContent)
            sendCounter += 1
        } else {
            // logger.error("encode失敗")
        }
    }
}
