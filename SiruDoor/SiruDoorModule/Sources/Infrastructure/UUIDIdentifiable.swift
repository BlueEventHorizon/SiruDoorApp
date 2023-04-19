//
//  UUIDIdentifiable.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/21.
//

import Foundation

public protocol UUIDIdentifiable: Identifiable, Equatable {
    var id: UUID { get }
}
