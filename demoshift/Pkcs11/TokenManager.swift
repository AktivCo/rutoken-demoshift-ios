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
}

class TokenManager {
    static let shared = TokenManager()

    let rtengine: OpaquePointer

    private var activeToken: Token?
    private var semaphore = DispatchSemaphore(value: 0)

    public func waitForToken() -> Token? {
        if let t = self.activeToken {
            return t
        }
        self.semaphore.wait()
        return self.activeToken
    }

    public func cancelWait() {
        self.semaphore.signal()
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

        startMonitoring()
    }

    deinit {
        C_Finalize(nil)

        ENGINE_unregister_pkey_asn1_meths(rtengine)
        ENGINE_unregister_pkey_meths(rtengine)
        ENGINE_unregister_digests(rtengine)
        ENGINE_unregister_ciphers(rtengine)

        rt_eng_final()
    }

    private func startMonitoring() {
        DispatchQueue.global(qos: .default).async {
            var count: UInt = 0
            var rv = C_GetSlotList(CK_BBOOL(CK_TRUE), nil, &count)
            guard rv == CKR_OK else {
                return
            }

            if count != 0 {
                var slots = Array(repeating: CK_SLOT_ID(0), count: Int(count))
                rv = C_GetSlotList(CK_BBOOL(CK_TRUE), &slots, &count)
                guard rv == CKR_OK else {
                    return
                }

                guard let t = Token(slot: slots[0]) else {
                    return
                }
                self.activeToken = t
            }

            while true {
                var slotId: UInt = 0
                rv = C_WaitForSlotEvent(0, &slotId, nil)
                guard rv != CKR_CRYPTOKI_NOT_INITIALIZED else {
                    return
                }
                guard rv == CKR_OK else {
                    continue
                }

                var slotInfo = CK_SLOT_INFO()
                rv = C_GetSlotInfo(slotId, &slotInfo)
                guard rv == CKR_OK else {
                    continue
                }

                if slotInfo.flags & UInt(CKF_TOKEN_PRESENT) == 0 && self.activeToken?.slot == slotId {
                    self.activeToken = nil
                }
                if slotInfo.flags & UInt(CKF_TOKEN_PRESENT) != 0 {
                    guard let t = Token(slot: slotId) else {
                        continue
                    }
                    self.activeToken = t
                    self.semaphore.signal()
                }
            }
        }
    }
}
