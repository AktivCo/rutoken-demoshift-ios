//
//  TokenManager.swift
//  demoshift
//
//  Created by Андрей Трифонов on 22.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Foundation


enum TokenManagerError: Error {
    case tokenNotFound
    case wrongToken
    case unknownError
}

class TokenManager {
    static let shared = TokenManager()

    let rtengine: OpaquePointer

    public func isConnected(token: Token) -> Bool {
        var slotInfo = CK_SLOT_INFO()
        let rv = C_GetSlotInfo(token.slot, &slotInfo)
        guard rv == CKR_OK else {
            return false
        }

        if slotInfo.flags & UInt(CKF_TOKEN_PRESENT) == 0 {
            return false
        }

        return true
    }

    public func getToken() throws -> Token {
        var ctr: UInt = 0
        var rv = C_GetSlotList(CK_BBOOL(CK_TRUE), nil, &ctr)
        guard rv == CKR_OK else {
            throw TokenManagerError.unknownError
        }

        guard ctr != 0 else {
            throw TokenManagerError.tokenNotFound
        }

        var slots = Array(repeating: CK_SLOT_ID(0), count: Int(ctr))
        rv = C_GetSlotList(CK_BBOOL(CK_TRUE), &slots, &ctr)
        guard rv == CKR_OK else {
            throw TokenManagerError.unknownError
        }

        let tokens = slots.compactMap { Token(slot: $0) }
        guard let token = tokens.first(where: { $0.type == .NFC }) else {
            throw TokenManagerError.tokenNotFound
        }

        return token
    }

    private init() {
        let ENGINE_METHOD_ALL: UInt32 = 0xFFFF
        let ENGINE_METHOD_RAND: UInt32 = 0x0008

        var r = rt_eng_init()
        assert(r == 1)

        rtengine = rt_eng_get0_engine()

        r = ENGINE_set_default(rtengine, ENGINE_METHOD_ALL - ENGINE_METHOD_RAND)
        assert(r == 1)

        var initArgs = CK_C_INITIALIZE_ARGS()
        initArgs.flags = UInt(CKF_OS_LOCKING_OK)

        let rv = C_Initialize(&initArgs)
        assert(rv == CKR_OK)
    }

    deinit {
        C_Finalize(nil)

        ENGINE_unregister_pkey_asn1_meths(rtengine)
        ENGINE_unregister_pkey_meths(rtengine)
        ENGINE_unregister_digests(rtengine)
        ENGINE_unregister_ciphers(rtengine)

        rt_eng_final()
    }
}
