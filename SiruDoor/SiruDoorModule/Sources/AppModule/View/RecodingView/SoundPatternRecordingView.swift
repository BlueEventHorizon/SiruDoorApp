//
//  SoundPatternRecordingView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/05/21.
//

import BwSwiftUI
import Domain
import SwiftUI

struct SoundPatternRecordingView: View {
    @StateObject var soundAnalyzer = SoundAnalyzer.shared
    @State var enableDeleteButton = true

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                topSpacer()

                #if canImport(Charts)
                    SoundInformationView()
                        .environmentObject(soundAnalyzer)
                #else

                #endif

                DividerView()

                Text("判定したい音の他は、できるだけ雑音を入れないようにして記録してください")
                    .foregroundColor(UIColor.red.color)
                    .font(.callout)
                    .padding(.horizontal, 40)

                SoundRecordingView(soundAnalyzer: soundAnalyzer)
                // .environmentObject(soundAnalyzer)

                BorderedLabelButton(text: .constant("記録した音を削除"), imageName: .constant("trash"), textStyle: .default, borderStyle: .shadowed, toggleValue: .constant(true), enable: $enableDeleteButton) { _ in
                    soundAnalyzer.deletePattern()
                }
                Spacer()
            }
        }
        .onChange(of: soundAnalyzer.state) { newState in
            enableDeleteButton = (newState != .noReference)
        }
        .onAppear {
            enableDeleteButton = !soundAnalyzer.referencePeaksArray.isEmpty
        }
    }
}

struct SoundPatternRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        SoundPatternRecordingView()
    }
}
