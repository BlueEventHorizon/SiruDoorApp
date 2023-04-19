//
//  SoundControlProtocol.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/05/04.
//

import Foundation

protocol SoundControlProtocol {
    func configure()
    func startAudioCapture()
    func stopAudioCapture()
    func startPlay()
    func stopPlay()

    var audioLevel: Float { get }
}

extension SoundControlProtocol {
    func configure() {}
    func startAudioCapture() {}
    func stopAudioCapture() {}
    func startPlay() {}
    func stopPlay() {}

    var audioLevel: Float {
        0
    }
}
