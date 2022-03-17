//
//  AddVcrInteractor.swift
//  demoshift
//
//  Created by Александр Иванов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine
import SwiftUI


class AddVcrInteractor {
    private var routingState: RoutingState
    private let vcrWrapper: VcrWrapper
    private var state: AddVcrState
    private var timer: Timer?
    private var maxTime: CGFloat = 0
    private let timerInterval: CGFloat = 0.01
    private var startTime: UInt64 = 0

    private var readers = [VcrInfo]()
    private var cancellable = Set<AnyCancellable>()

    init(routingState: RoutingState, state: AddVcrState, vcrWrapper: VcrWrapper) {
        self.routingState = routingState
        self.state = state
        self.vcrWrapper = vcrWrapper
        self.vcrWrapper.vcrs
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] vcrs in
                if self.routingState.showAddVCRView {
                    if vcrs.contains(where: { [unowned self] vcr in
                        !self.readers.contains(where: { $0.name == vcr.name }) }) {
                        self.routingState.showVCRListView = false
                        self.routingState.showAddVCRView = false
                    }
                }
                readers = vcrs
            })
            .store(in: &cancellable)
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

    private func stopQrTimer() {
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

    public func willAppear(maxTime: CGFloat) {
        self.maxTime = maxTime
        loadQrCode()
    }

    public func willDisappear() {
        stopQrTimer()
    }
}
