//
//  SiruDoorApp.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/05/21.
//

import AppModule
import SwiftUI

@main
struct SiruDoorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.default

    var body: some Scene {
        WindowGroup {
            switch appState.viewState {
                case .splash:
                    SplashView()
                        .environmentObject(appState)
                        .onAppear {
                            Resolver.resolve()
                        }

                case .main:
                    SiruDoorMainView()
            }
        }
    }
}
