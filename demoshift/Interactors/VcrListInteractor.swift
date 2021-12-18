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
    private let pcscWrapper: PcscWrapper

    private var cancellable = Set<AnyCancellable>()

    init(state: VcrListState, pcscWrapper: PcscWrapper) {
        self.state = state
        self.pcscWrapper = pcscWrapper
        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] currentReaders in
                self.state.vcrs = (listPairedVCR() as? [[String: Any]] ?? []).compactMap { info in
                    guard let name = info["name"] as? String,
                          let id = info["fingerprint"] as? Data else {
                        return nil
                    }
                    return VcrInfo(id: id, name: name, isActive: currentReaders.contains(where: { name == $0.name }))
                }
            })
            .store(in: &cancellable)
    }

    public func unpairVcr(id: Data) {
        unpairVCR(id)
        state.vcrs.removeAll(where: { $0.id == id })
    }
}
