//
//  SettingView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/11.
//

import BwSwiftUI
import Domain
import Foundation
import SwiftUI

struct SettingView: View {
    @EnvironmentObject var nearPeerNotifier: NearPeerNotifier

    @State var toggleValue: Bool = false
    @State var peerNames: [PeerIdentifier] = []

    @State var maxPowerValueText: String = "300"
    @State var maxFrequencyText: String = "2000"
    @State var maxFrequencyOkToggleValue: Bool = false

    /// キーボードのフォーカス制御
    @FocusState var focus: Bool

    var body: some View {
        // swiftlint:disable:next closure_body_length
        ScrollView {
            // swiftlint:disable:next closure_body_length
            LazyVStack(alignment: .center, spacing: 40) {
                topSpacer()

                Text("このアプリの識別番号：\n\(AppUserDefault.networkIdentifier)")
                    .foregroundColor(UIColor.darkGray.color)
                    .font(.system(size: 17, weight: .regular))

                DividerView()

                if peerNames.isEmpty {
                    HStack {
                        Text("モニターへの接続なし")
                            .foregroundColor(UIColor.orange.color)
                            .padding(.horizontal, 35)
                            .font(.system(size: 17, weight: .regular))
                    }
                } else {
                    ForEach(peerNames) { name in
                        Text("\(name.displayName).\(String(name.id.uuidString.prefix(6)))に接続")
                            .foregroundColor(UIColor.darkGray.color)
                            .padding(.horizontal, 35)
                            .font(.system(size: 17, weight: .regular))
                    }

                    BorderedLabelButton(text: .constant("モニターにテスト送信する"), imageName: .constant(""), textStyle: .default, borderStyle: .shadowed, toggleValue: $toggleValue, enable: .constant(true)) { _ in
                        nearPeerNotifier.send(text: "テスト送信です")
                    }
                }

                DividerView()

                HStack {
                    Text("表示周波数の最大値：")
                        .foregroundColor(UIColor.darkGray.color)
                        .font(.system(size: 17, weight: .regular))

                    Spacer()

                    // TextField(text: $maxFrequencyText, placeHolder: $maxFrequencyText)
                    TextEditor(text: $maxFrequencyText)
                        .lineLimit(1)
                        .foregroundColor(UIColor.darkGray.color)
                        .frame(alignment: .center)
                        .multilineTextAlignment(.center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(/*@START_MENU_TOKEN@*/ .all/*@END_MENU_TOKEN@*/, 3)
                        .frame(width: 90)
                        .focused(self.$focus)

                    Text("Hz")
                        .foregroundColor(UIColor.darkGray.color)
                        .font(.system(size: 17, weight: .regular))
                        .padding(.trailing, 10)

                    BorderedLabelButton(text: .constant("設定"), imageName: .constant(""), textStyle: .default, borderStyle: .smallShadowed, toggleValue: $maxFrequencyOkToggleValue, enable: .constant(true)) { _ in
                        guard let maxFrequency = Float(maxFrequencyText) else { return }
                        guard maxFrequency > 10 else { maxFrequencyText = "10"; return }
                        guard maxFrequency < 20_000 else { maxFrequencyText = "20000.0"; return }

                        AppUserDefault.fftDisplayParams.maxFrequency = maxFrequency

                        self.focus = false
                    }
                }
                .padding(.horizontal, 40)
            }
            .onChange(of: nearPeerNotifier.peerNames) { names in
                peerNames = names
                print("🔶 \(peerNames)")
            }
            .onAppear {
                peerNames = nearPeerNotifier.peerNames

                maxPowerValueText = String(AppUserDefault.fftDisplayParams.maxPowerValue)
                maxFrequencyText = String(AppUserDefault.fftDisplayParams.maxFrequency)
            }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
