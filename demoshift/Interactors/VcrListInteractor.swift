//
//  VcrListInteractor.swift
//  demoshift
//
//  Created by Андрей Трифонов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//


class VcrListInteractor {
    private var state: VcrListState

    init(state: VcrListState) {
        self.state = state
    }

    public func loadAllVcrs() {
        state.vcrs = (listPairedVCR() as? [[String: Any]] ?? []).compactMap { info in
            guard let name = info["name"] as? String,
                  let id = info["fingerprint"] as? Data else {
                return nil
            }
            return VcrInfo(id: id, name: name)
        }
    }

    public func unpairVcr(id: Data) {
        unpairVCR(id)
    }
}
