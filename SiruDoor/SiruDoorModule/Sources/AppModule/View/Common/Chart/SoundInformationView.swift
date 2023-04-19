//
//  SoundBarChart.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/06/20.
//

import Domain
import SwiftUI

struct SoundInformationView: View {
    @EnvironmentObject var soundAnalyzer: SoundAnalyzer

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("マイクで集音中のデータ")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if #available(iOS 16.0, *) {
                SoundFFTDisplayView(values: soundAnalyzer.mFFTDisplayData)
                    .frame(height: 300)
            }
            Text("Hz（周波数）")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .listStyle(.plain)
        .navigationBarTitle("Input Sound", displayMode: .inline)
    }
}
