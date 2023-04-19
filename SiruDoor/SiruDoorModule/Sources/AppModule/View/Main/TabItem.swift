//
//  TabItem.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/07/18.
//

import Foundation

enum TabItem: Int {
    case recording
    case analyzing
    case monitor
    case setting

    var tabName: String {
        switch self {
            case .recording:
                return "音を登録"

            case .analyzing:
                return "音を判定"

            case .monitor:
                return "通知モニター"

            case .setting:
                return "設定"
        }
    }

    var title: String {
        switch self {
            case .recording:
                return "音を登録"

            case .analyzing:
                return "音を判定"

            case .monitor:
                return "通知モニター"

            case .setting:
                return "設定"
        }
    }

    var imageName: String {
        switch self {
            case .recording:
                return "record.circle"

            case .analyzing:
                return "ear.and.waveform"

            case .monitor:
                return "figure.walk.arrival"

            case .setting:
                return "gearshape"
        }
    }
}
