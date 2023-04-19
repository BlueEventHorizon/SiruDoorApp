//
//  AppState.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation

@MainActor
public final class AppState: ObservableObject {
    public enum ViewState {
        case splash
        case main
    }

    @Published public private(set) var viewState: ViewState = .splash

    public static let `default` = AppState()

    public func setViewState(_ viewState: ViewState) {
        self.viewState = viewState
    }
}
