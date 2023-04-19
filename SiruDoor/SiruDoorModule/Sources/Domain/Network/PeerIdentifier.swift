//
//  PeerIdentifier.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/09/20.
//

import Foundation
import Infrastructure

public struct PeerIdentifier: UUIDIdentifiable {
    public let id: UUID
    public let displayName: String

    public init(id: UUID, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
