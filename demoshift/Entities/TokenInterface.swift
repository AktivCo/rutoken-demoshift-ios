//
//  TokenInterface.swift
//  demoshift
//
//  Created by Александр Иванов on 11.11.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

enum TokenInterface: Codable, Equatable {
    case USB
    case SC
    case NFC
}

extension TokenInterface {
    init?(_ value: CK_ULONG) {
        switch value {
        case CK_ULONG(INTERFACE_TYPE_NFC_TYPE_A), CK_ULONG(INTERFACE_TYPE_NFC_TYPE_B):
            self = .NFC
        case CK_ULONG(INTERFACE_TYPE_USB):
            self = .USB
        case CK_ULONG(INTERFACE_TYPE_ISO):
            self = .SC
        default:
            return nil
        }
    }
}

extension Sequence where Iterator.Element == TokenInterface {
    init(bits: CK_ULONG) where Self == [TokenInterface] {
        self = [INTERFACE_TYPE_ISO,
                INTERFACE_TYPE_NFC_TYPE_A,
                INTERFACE_TYPE_NFC_TYPE_B,
                INTERFACE_TYPE_USB]
                   .compactMap({
                       let mask = CK_ULONG($0)
                       guard bits & mask == mask else { return nil }
                       return TokenInterface(mask)
                   })
    }
}
