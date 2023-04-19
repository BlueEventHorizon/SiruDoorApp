//
//  MonitorView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/25.
//

import Domain
import Foundation
import SwiftUI

struct MonitorView: View {
    @StateObject private var nearPeerMonitor: NearPeerMonitor = .shared
    @EnvironmentObject var nearPeerNotifier: NearPeerNotifier

    @State var nearPeerInitialized: Bool = false

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 200)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("「通知モニター」では、別の端末の「しるドア」アプリから発行される通知を表示します。")
                        .foregroundColor(UIColor.darkGray.color)
                        .padding(.horizontal, 35)
                        .font(.system(size: 17, weight: .bold))

                    Text("「通知モニター」使用中は、この端末で音の検出は行いません。")
                        .foregroundColor(UIColor.orange.color)
                        .padding(.horizontal, 35)
                        .font(.system(size: 15, weight: .regular))

                    Text("このモードはバックグラウンドでは動作しません。ご注意ください。")
                        .foregroundColor(UIColor.orange.color)
                        .padding(.horizontal, 35)
                        .font(.system(size: 15, weight: .regular))
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .onAppear {
            nearPeerNotifier.suspend()
            if nearPeerInitialized {
                nearPeerMonitor.resume()
            } else {
                nearPeerMonitor.start()
                nearPeerInitialized = true
            }
        }
        .onDisappear {
            nearPeerMonitor.suspend()
            nearPeerNotifier.resume()
        }
    }
}

struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
}
