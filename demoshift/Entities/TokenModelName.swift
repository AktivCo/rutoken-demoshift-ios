//
//  TokenModelName.swift
//  demoshift
//
//  Created by Александр Иванов on 16.11.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

enum TokenModelName: String {
    case rutoken2 = "Рутокен ЭЦП 2.0"
    case rutoken3 = "Рутокен ЭЦП 3.0"
    case pki = "Рутокен ЭЦП PKI"
    case ble = "Рутокен ЭЦП 3.0 Bluetooth"
    case unsupported = "Неподдерживаемый Рутокен"
}

extension TokenModelName {
    init(_ hardwareVersion: CK_VERSION, _ firmwareVersion: CK_VERSION, _ tokenClass: CK_ULONG) {
        if tokenClass == TOKEN_CLASS_ECP_BT {
            self = .ble
            return
        }

        guard tokenClass == TOKEN_CLASS_ECP || tokenClass == TOKEN_CLASS_ECPDUAL else {
            self = .unsupported
            return
        }

        let AA = hardwareVersion.major
        let BB = hardwareVersion.minor
        let CC = firmwareVersion.major
        let DD = firmwareVersion.minor

        switch (AA, BB, CC, DD) {
        case (_, _, 21, _),
             (_, _, 25, _),
             (20, _, 23...24, _),
             (20, _, 26, _),
             (54, _, 23, 2),
             (55, _, 24, _),
             (55, _, 27, _),
             (58, _, 27, _),
             (59, _, 26...27, _):
            self = .rutoken2
        case (54, _, 23, 0),
             (54, _, ..<20, _):
            self = .pki
        case (_, _, 30, _),
             (60, _, 28, _):
            self = .rutoken3
        default:
            self = .unsupported
        }
    }
}
