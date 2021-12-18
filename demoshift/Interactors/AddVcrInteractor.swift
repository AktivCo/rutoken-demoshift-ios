//
//  AddVcrInteractor.swift
//  demoshift
//
//  Created by Александр Иванов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI
import UIKit


class AddVcrInteractor {
    private var state: AddVcrState
    private var timer: Timer?
    public var maxTime: CGFloat = 0
    private let timerInterval: CGFloat = 0.01
    private var startTime: UInt64 = 0

    init(state: AddVcrState) {
        self.state = state
    }

    deinit {
        timer?.invalidate()
    }

    public func loadQrCode() {
        DispatchQueue.main.async { [unowned self] in
            guard let strBase64 = generatePairingQR(),
                  let data = Data(base64Encoded: strBase64) else {
                      state.qrCode = nil
                      state.currentTime = 0.0
                      state.isBlurQr = true
                      return
                  }
            state.qrCode = UIImage(data: data)
            state.isBlurQr = false
            startQrTimer()
        }
    }

    public func stopQrTimer() {
        timer?.invalidate()
        state.isBlurQr = true
        state.currentTime = 0
    }

    private func startQrTimer() {
        startTime = DispatchTime.now().uptimeNanoseconds
        state.currentTime = maxTime
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [unowned self] _ in
            receiveTimerUpdate()
        }
    }

    private func receiveTimerUpdate() {
        let currentTime = DispatchTime.now().uptimeNanoseconds
        let delta = Double(currentTime - startTime) / 1_000_000_000
        if (state.currentTime - delta) < 0.0 {
            stopQrTimer()
            return
        }
        state.currentTime -= delta
        startTime = currentTime
    }
}
