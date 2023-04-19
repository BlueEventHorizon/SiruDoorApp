//
//  NearPeerNotifier.swift
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

public protocol NearPeerNotifierDependency {
    /// InfoPlistに記述が必要
    var serviceType: String { get }

    // Info.plistで記述される
    var appName: String { get }

    /// 永続的かつユニークである必要がある
    var identifier: String { get }

    var myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { get }

    var targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? { get }
}

public protocol DependencyInjectedSingleton: AnyObject {
    associatedtype Dependency
    associatedtype InstanceType

    static var shared: InstanceType { get }

    static func resolve(dependency: Dependency)

    static func getInstanceForTest(dependency: Dependency) -> InstanceType
}

public class NearPeerNotifier: ObservableObject {
    public typealias Dependency = NearPeerNotifierDependency
    public typealias InstanceType = NearPeerNotifier

    // Singleton ＆ Dependency Injection
    private static var defaultDependency: Dependency?
    private let dependency: Dependency

    @Published public var peerNames: [PeerIdentifier] = []
    @Published public var receivedText: String = "まだ受信していません"

    private let nearPeer: NearPeer

    /// 複数の「しるドアモニター」の識別子を格納する
    private let peers = StructHolder()

    private var sendCounter: Int = 0

    // Singleton ＆ Dependency Injection

    public static var shared: InstanceType {
        InstanceType(dependency: defaultDependency!)
    }

    public static func resolve(dependency: Dependency) {
        defaultDependency = dependency
    }

    public static func getInstanceForTest(dependency: Dependency) -> InstanceType {
        let instance = InstanceType(dependency: dependency)
        assert(NSClassFromString("XCTest") != nil, "テストのみで呼び出し可能")
        return instance
    }

    private init(dependency: Dependency) {
        self.dependency = dependency

        // 一度に接続できる「しるドアモニター」は１つだけ
        nearPeer = NearPeer(maxPeers: 1)

        nearPeer.start(serviceType: dependency.serviceType,
                       displayName: "\(dependency.appName).\(dependency.identifier)",
                       myDiscoveryInfo: dependency.myDiscoveryInfo,
                       targetDiscoveryInfo: dependency.targetDiscoveryInfo)
        nearPeer.onConnected { peer in
            Task {
                await MainActor.run {
                    // logger.info("🔵 \(peer.displayName) Connected", instance: self)
                    // TODO: 切断された時の処理を追加すること

                    let peerComponents = peer.displayName.components(separatedBy: ".")

                    if let displayName = peerComponents.first, let uuidString = peerComponents.last, let uuid = UUID(uuidString: uuidString) {
                        self.peers.set(PeerIdentifier(id: uuid, displayName: displayName))
                        self.peerNames = self.peers.map {
                            $0 as! PeerIdentifier
                        }

                        // logger.info("🟡 peerName | \(displayName), peerIdentifier = \(uuidString)", instance: self)
                    }
                }
            }
        }

        nearPeer.onDisconnect { peer in
            Task {
                await MainActor.run {
                    // logger.warning("🔴 \(peer) is disconnected")

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
            // logger.info("🟢 Received", instance: self)

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
