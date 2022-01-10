//
//  PcscWrapperInteractor.swift
//  demoshift
//
//  Created by Vova Badyaev on 24.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


class PcscWrapperInteractor {
    private let pcscWrapper: PcscWrapper
    private var readers = [Reader]()

    private var cancellable = Set<AnyCancellable>()

    init(_ pcscWrapper: PcscWrapper) {
        self.pcscWrapper = pcscWrapper
        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] currentReaders in
                readers = currentReaders
            })
            .store(in: &cancellable)
    }

    public func startNfc(withWaitMessage waitMessage: String, workMessage: String) throws {
        guard let reader = readers.first(where: {$0.type == .vcr || $0.type == .nfc }) else {
            throw ReaderError.readerUnavailable
        }
        try pcscWrapper.startNfc(onReader: reader.name, waitMessage: waitMessage, workMessage: workMessage)
    }

    public func stopNfc(withMessage message: String) {
        guard let reader = readers.first(where: {$0.type == .vcr || $0.type == .nfc }) else {
            return
        }
        try? pcscWrapper.stopNfc(onReader: reader.name, withMessage: message)
    }
}
