//
//  DividerView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/09/19.
//

import SwiftUI

struct DividerView: View {
    var body: some View {
        Divider()
            .foregroundColor(UIColor.secondaryLabel.color)
            .frame(height: 1.0)
            .padding(.horizontal, 20)
    }
}

struct DividerView_Previews: PreviewProvider {
    static var previews: some View {
        DividerView()
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Divider View")
    }
}
