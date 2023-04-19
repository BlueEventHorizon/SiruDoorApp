//
//  SoundFFTDisplayView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/12.
//

import Charts
import Domain
import SwiftUI

// https://developer.apple.com/documentation/Charts

@available(iOS 16.0, *)
struct SoundFFTDisplayView: View {
    var values: [FFTValue]

    var body: some View {
        HStack {
            Chart(values, id: \.id) {
                BarMark(
                    x: .value("周波数(Hz)", $0.frequency),
                    y: .value("音圧", $0.value)
                )
                .opacity(0.5)
            }
            .chartYScale(domain: 0 ... AppUserDefault.fftDisplayParams.maxPowerValue)
            .chartPlotStyle { content in
                content.background(.gray.opacity(0.1))
            }
            .padding(25)
        }
    }
}
