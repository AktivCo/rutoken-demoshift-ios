//
//  VcrListInteractor.swift
//  demoshift
//
//  Created by Андрей Трифонов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


class VcrListInteractor {
    private var state: VcrListState
    private let vcrWrapper: VcrWrapper

    private var cancellable = Set<AnyCancellable>()

    init(state: VcrListState, vcrWrapper: VcrWrapper) {
        self.state = state
        self.vcrWrapper = vcrWrapper
        self.vcrWrapper.vcrs
            .receive(on: DispatchQueue.main)
            .assign(to: \.vcrs, on: state)
            .store(in: &cancellable)
    }

    public func unpairVcr(id: Data) {
        vcrWrapper.unpairVcr(id: id)
    }
}
