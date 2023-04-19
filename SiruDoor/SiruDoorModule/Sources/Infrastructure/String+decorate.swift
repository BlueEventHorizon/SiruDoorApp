//
//  String+decorate.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation
import SwiftUI

extension String {
    public func decorate(_ target: String) -> AttributedString {
        var attributedString = AttributedString(self)

        if let range = attributedString.range(of: target) {
            attributedString[range].foregroundColor = .accentColor
            attributedString[range].font = .system(size: 17, weight: .bold)
        }
        return attributedString
    }
}
