//
//  AnalyzingResultView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/23.
//

import SwiftUI

struct AnalyzingStateView: View {
    @Binding var state: AnalyzingState
    @State var imageName: String = "questionmark.square.dashed"
    @State var stateText: String = L10n.判定中です // "判定中です"

    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            Text(stateText)
                .foregroundColor(UIColor.darkGray.color)
                .font(.system(size: 17, weight: .regular))
        }
        .onChange(of: state) { state in
            switch state {
                case .match:
                    stateText = L10n.通知しました // "通知しました"
                    imageName = "paperplane"

                case .notMatch:
                    stateText = "判定中です"
                    imageName = "ear.and.waveform"

                case .noReference:
                    stateText = "検出すべき音が記録されていません"
                    imageName = "questionmark.square.dashed"

                default:
                    break
            }
        }
    }
}
