//
//  BluetoothHelper.swift
//  demoshift
//
//  Created by Vova Badyaev on 24.03.2023.
//  Copyright © 2023 Aktiv Co. All rights reserved.
//

import Combine
import CoreBluetooth


class BluetoothHelper: NSObject {
    private var centralManager: CBCentralManager
    public let state = CurrentValueSubject<CBManagerState, Never>(.unknown)

    override init() {
        self.centralManager = CBCentralManager(delegate: nil, queue: DispatchQueue.global(qos: .default))
        super.init()
        centralManager.delegate = self
    }
}

extension BluetoothHelper: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state.send(central.state)
    }
}
