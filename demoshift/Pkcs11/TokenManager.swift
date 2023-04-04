//
//  TokenManager.swift
//  demoshift
//
//  Created by Андрей Трифонов on 22.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Combine
import Foundation


enum TokenManagerError: Error {
    case tokenNotFound
    case wrongToken
    case unknownError
}

class TokenManager {
    static let shared = TokenManager()

    let rtengine: OpaquePointer

    private var tokensPublisher = CurrentValueSubject<[Token], Never>([])

    public func tokens() -> AnyPublisher<[Token], Never> {
        return tokensPublisher.share().eraseToAnyPublisher()
    }

    public func isConnected(token: Token) -> Bool {
        return isPresent(slotID: token.slot)
    }

    private func isPresent(slotID: CK_SLOT_ID) -> Bool{
        var slotInfo = CK_SLOT_INFO()
        let rv = C_GetSlotInfo(slotID, &slotInfo)
        guard rv == CKR_OK else {
            return false
        }

        if slotInfo.flags & UInt(CKF_TOKEN_PRESENT) == 0 {
            return false
        }

        return true
    }

    private func getTokens() throws -> [Token] {
        var ctr: UInt = 0
        var rv = C_GetSlotList(CK_BBOOL(CK_TRUE), nil, &ctr)
        guard rv == CKR_OK else {
            throw TokenManagerError.unknownError
        }

        guard ctr != 0 else {
            return []
        }

        var slots = Array(repeating: CK_SLOT_ID(0), count: Int(ctr))
        rv = C_GetSlotList(CK_BBOOL(CK_TRUE), &slots, &ctr)
        guard rv == CKR_OK else {
            throw TokenManagerError.unknownError
        }

        return slots.compactMap { Token(slot: $0) }
    }

    private init() {
        let ENGINE_METHOD_ALL: UInt32 = 0xFFFF
        let ENGINE_METHOD_RAND: UInt32 = 0x0008

        var r = rt_eng_load_engine()
        assert(r == 1)

        rtengine = rt_eng_get0_engine()
        ENGINE_init(rtengine)

        r = ENGINE_set_default(rtengine, ENGINE_METHOD_ALL - ENGINE_METHOD_RAND)
        assert(r == 1)

        var initArgs = CK_C_INITIALIZE_ARGS()
        initArgs.flags = UInt(CKF_OS_LOCKING_OK)

        var rv = C_Initialize(&initArgs)
        assert(rv == CKR_OK)

        DispatchQueue.global().async { [unowned self] in
            if let tokens = try? getTokens() {
                tokensPublisher.send(tokens)
            }

            while true {
                var slotId = CK_SLOT_ID()
                rv = C_WaitForSlotEvent(0, &slotId, nil)

                guard rv != CKR_CRYPTOKI_NOT_INITIALIZED else { return }
                guard rv == CKR_OK else { continue }

                var tokens = tokensPublisher.value
                tokens.removeAll { $0.slot == slotId }

                if isPresent(slotID: slotId),
                   let token = Token(slot: slotId) {
                    tokens.append(token)
                }

                tokensPublisher.send(tokens)
            }
        }
    }

    deinit {
        C_Finalize(nil)

        ENGINE_unregister_pkey_asn1_meths(rtengine)
        ENGINE_unregister_pkey_meths(rtengine)
        ENGINE_unregister_digests(rtengine)
        ENGINE_unregister_ciphers(rtengine)
        ENGINE_finish(rt_eng_get0_engine())

        rt_eng_unload_engine()
    }
}
