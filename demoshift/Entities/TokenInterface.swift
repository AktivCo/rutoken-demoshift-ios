//
//  TokenInterface.swift
//  demoshift
//
//  Created by Александр Иванов on 11.11.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

enum TokenInterface: Codable {
    case USB
    case BT
    case NFC
}

extension TokenInterface {
    init?(_ value: CK_ULONG) {
        switch value {
        case CK_ULONG(INTERFACE_TYPE_BT):
            self = .BT
        case CK_ULONG(INTERFACE_TYPE_NFC):
            self = .NFC
        case CK_ULONG(INTERFACE_TYPE_USB):
            self = .USB
        default:
            return nil
        }
    }
}

extension Sequence where Iterator.Element == TokenInterface {
    init(bits: CK_ULONG) where Self == [TokenInterface] {
        self = [INTERFACE_TYPE_BT,
                INTERFACE_TYPE_NFC,
                INTERFACE_TYPE_USB]
                   .compactMap({
                       let mask = CK_ULONG($0)
                       guard bits & mask == mask else { return nil }
                       return TokenInterface(mask)
                   })
    }
}