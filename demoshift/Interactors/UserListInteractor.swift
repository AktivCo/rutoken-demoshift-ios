//
//  UserListInteractor.swift
//  demoshift
//
//  Created by Андрей Трифонов on 15.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


class UserListInteractor {
    private let notificationManager = NotificationManager()
    private let pcscWrapper: PcscWrapper
    private var readers = [Reader]()
    private var cancellable = Set<AnyCancellable>()

    init(_ pcscWrapper: PcscWrapper) {
        self.pcscWrapper = pcscWrapper
        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] newReaders in
                readers
                    .filter { $0.type != .nfc }
                    .forEach { reader in
                    if !newReaders.contains(where: { $0.name == reader.name }) {
                        notificationManager.pushNotification(withTitle: "Отключение",
                                                             body: "\(reader.name) был отключен от устройства")
                    }
                }

                newReaders
                    .filter { $0.type != .nfc }
                    .forEach { newReader in
                    if !readers.contains(where: { $0.name == newReader.name }) {
                        notificationManager.pushNotification(withTitle: "Подключение",
                                                             body: "\(newReader.name) был подключен к устройству")
                    }
                }

                readers = newReaders
            })
            .store(in: &cancellable)
    }
}
