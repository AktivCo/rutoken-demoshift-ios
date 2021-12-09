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
            guard let name = info["name"] as? String else {
                return nil
            }
            return VcrInfo(name: name)
        }
    }
}
