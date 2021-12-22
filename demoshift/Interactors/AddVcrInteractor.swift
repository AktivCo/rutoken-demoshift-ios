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
    private let pcscWrapper: PcscWrapper
    private var state: AddVcrState
    private var timer: Timer?
    private var maxTime: CGFloat = 0
    private let timerInterval: CGFloat = 0.01
    private var startTime: UInt64 = 0

    private var readers = [String]()
    private var cancellable = Set<AnyCancellable>()

    init(routingState: RoutingState, state: AddVcrState, pcscWrapper: PcscWrapper) {
        self.routingState = routingState
        self.state = state
        self.pcscWrapper = pcscWrapper
        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] newReaders in
                if self.routingState.showAddVCRView {
                    newReaders
                        .filter { $0.type == .vcr }
                        .forEach { newReader in
                            if !readers.contains(where: { $0 == newReader.name }) {
                                self.routingState.showVCRListView = false
                                self.routingState.showAddVCRView = false
                            }
                        }
                }
                readers = (listPairedVCR() as? [[String: Any]] ?? []).compactMap { info in
                    guard let name = info["name"] as? String else {
                        return nil
                    }
                    return name
                }
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
