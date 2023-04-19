//
//  SoundPatternAnalyzingView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/23.
//

import Domain
import Foundation
import SwiftUI

enum AnalyzingState {
    case none
    case match
    case notMatch
    case noReference
}

struct SoundPatternAnalyzingView: View {
    @EnvironmentObject var nearPeerNotifier: NearPeerNotifier
    @StateObject var soundAnalyzer = SoundAnalyzer.shared
    @State var state: AnalyzingState = .none

    var body: some View {
        VStack(spacing: 40) {
            topSpacer()

            #if canImport(Charts)
                SoundInformationView()
                    .environmentObject(soundAnalyzer)
            #else

            #endif

            DividerView()

            AnalyzingStateView(state: $state)

            Spacer()
        }
        .onChange(of: soundAnalyzer.state) { newState in
            if newState == .noReference {
                state = .noReference
            } else {
                if newState == .match {
                    state = .match
                    nearPeerNotifier.send(text: "登録した音を検知しました")
                } else {
                    state = .notMatch
                }
            }
        }
        .onAppear {
            soundAnalyzer.startMonitor()

            if soundAnalyzer.referencePeaksArray.isEmpty {
                state = .noReference
            } else {
                state = .notMatch
            }
        }
        .onDisappear {
            soundAnalyzer.stopMonitor()
        }
    }
}

struct SoundPatternAnalyzingView_Previews: PreviewProvider {
    static var previews: some View {
        SoundPatternRecordingView()
    }
}
