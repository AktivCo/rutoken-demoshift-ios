//
//  AddVcrInteractor.swift
//  demoshift
//
//  Created by Александр Иванов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import UIKit


class AddVcrInteractor {
    private var state: AddVcrState

    init(state: AddVcrState) {
        self.state = state
    }

    public func loadQrCode() {
        DispatchQueue.main.async { [unowned self] in
            guard let strBase64 = generatePairingQR(),
                  let data = Data(base64Encoded: strBase64) else {
                      self.state.qrCode = nil
                      return
                  }
            self.state.qrCode = UIImage(data: data)
        }
    }
}
