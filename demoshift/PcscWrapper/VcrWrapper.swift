//
//  VcrWrapper.swift
//  demoshift
//
//  Created by Александр Иванов on 12.01.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

import Combine


class VcrWrapper {
    private struct  ListVcr {
        let id: Data
        let name: String
        let cert: String
    }

    private var vcrsPublisher = CurrentValueSubject<[VcrInfo], Never>([])
    private let pcscWrapper: PcscWrapper
    private var cancellable = Set<AnyCancellable>()
    var vcrs: AnyPublisher<[VcrInfo], Never> {
        return vcrsPublisher.share().eraseToAnyPublisher()
    }

    init(pcscWrapper: PcscWrapper) {
        self.pcscWrapper = pcscWrapper
        self.pcscWrapper.readers()
            .sink(receiveValue: { [unowned self] currentReaders in
                vcrsPublisher.send(listVcrs().map { vcr in
                    return VcrInfo(id: vcr.id,
                                   name: vcr.name,
                                   isActive: currentReaders.contains(where: { vcr.name == $0.name }))
                })
            })
            .store(in: &cancellable)
    }

    func unpairVcr(id: Data) {
        unpairVCR(id)
        vcrsPublisher.value.removeAll(where: { $0.id == id })
    }

    private func listVcrs() -> [ListVcr] {
        return (listPairedVCR() as? [[String: Any]] ?? []).compactMap { info in
            guard let fingerprint = info["fingerprint"] as? Data,
                  let name = info["name"] as? String,
                  let cert = info["cert"] as? String else {
                      return nil
                  }
            return ListVcr(id: fingerprint, name: name, cert: cert)
        }
    }
}
