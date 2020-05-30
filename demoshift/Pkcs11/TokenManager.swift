//
//  TokenManager.swift
//  demoshift
//
//  Created by Андрей Трифонов on 22.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Foundation

enum TokenError: Error {
    case incorrectPin
    case lockedPin
    case pkcs11Error(rv: Int32)
}


class Token {
    let slot: CK_SLOT_ID
    let serial: String

    private var session = CK_SESSION_HANDLE(NULL_PTR)

    init?(slot: CK_SLOT_ID) {
        self.slot = slot

        var tokenInfo = CK_TOKEN_INFO()
        var rv = C_GetTokenInfo(slot, &tokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        var rawSerial = tokenInfo.serialNumber
        self.serial = withUnsafePointer(to: &rawSerial) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: tokenInfo.serialNumber)) {
                String(cString: $0)
            }
        }.trimmingCharacters(in: .whitespacesAndNewlines)

        rv = C_OpenSession(self.slot, CK_FLAGS(CKF_SERIAL_SESSION), nil, nil, &self.session)
        guard rv == CKR_OK else {
            return nil
        }
    }

    public func login(pin: String) throws {
        var rawPin: [UInt8] = Array(pin.utf8)
        let rv = C_Login(self.session, CK_USER_TYPE(CKU_USER), &rawPin, CK_ULONG(pin.count))
        guard rv == CKR_OK || rv == CKR_USER_ALREADY_LOGGED_IN else {
            switch Int32(rv) {
            case CKR_PIN_INCORRECT:
                throw TokenError.incorrectPin
            case CKR_PIN_LOCKED:
                throw TokenError.lockedPin
            default:
                throw TokenError.pkcs11Error(rv: Int32(rv))
            }
        }
        return
    }
}

class TokenManager {
    static let shared = TokenManager()

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
        var initArgs = CK_C_INITIALIZE_ARGS()
        initArgs.flags = UInt(CKF_OS_LOCKING_OK)

        C_Initialize(&initArgs)
        startMonitoring()
    }

    deinit {
        C_Finalize(nil)
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
