//
//  TopSpacerView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/09/19.
//

import SwiftUI

struct TopSpacerView: View {
    var body: some View {
        Spacer()
            .frame(height: 15)
    }
}

@ViewBuilder public func topSpacer() -> some View {
    Spacer()
        .frame(height: 15)
}
