//
//  SimpleNotificationContent.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/21.
//

import Foundation

public struct SimpleNotificationContent: Codable {
    public let title: String
    public let subtitle: String
    public let body: String
    public let image: String?

    public init(title: String, subtitle: String, body: String, image: String?) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.image = image
    }
}
