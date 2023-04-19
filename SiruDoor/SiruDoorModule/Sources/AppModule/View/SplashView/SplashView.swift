//
//  SplashView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation
import Infrastructure
import SwiftUI

public struct SplashView: View {
    @StateObject var viewModel: SplashViewModel = .init()

    public init() {}

    public var body: some View {
        VStack {
            Text("しるドア".decorate("ドア"))
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.start()
        }
    }
}

final class SplashViewModel: ObservableObject {
    func start() {
        Task {
            try? await Task.sleep(nanoseconds: TimeValueObject(seconds: 1.0).nanoseconds)

            await AppState.default.setViewState(.main)
        }
    }
}
