//
//  SoundRecordingView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/12.
//

import BwSwiftUI
import Domain
import SwiftUI

struct SoundRecordingView: View {
    @ObservedObject var soundAnalyzer: SoundAnalyzer

    @State var text = "音の記録を開始"
    @State var imageName = "record.circle"
    @State var toggleValue: Bool = false

    var body: some View {
        VStack(alignment: .center) {
            BorderedLabelButton(text: $text, imageName: $imageName, textStyle: .default, borderStyle: .shadowed, toggleValue: $toggleValue, enable: .constant(true)) { toggleValue in
                if toggleValue {
                    text = "音の記録を停止"
                    imageName = "stop.fill"
                    soundAnalyzer.startRecordPattern()
                } else {
                    text = "音の記録を開始"
                    imageName = "record.circle"
                    soundAnalyzer.endRecordPattern()
                }
            }
        }
    }
}
