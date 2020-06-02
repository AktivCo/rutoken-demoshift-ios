//
//  Token.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.06.2020.
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

    public func enumerateCerts() throws -> [Cert] {
        var certs: [Cert] = []
        let objects = self.findObjects(ofType: CKO_CERTIFICATE)
        for obj in objects {
            guard let cert = Cert(fromHandle: obj, inSession: self.session) else {
                continue
            }

            //Check whether corresponding private key exists
            guard findObject(ofType: CKO_PRIVATE_KEY, byId: cert.id) != nil else {
                continue
            }
            certs.append(cert)
        }
        return certs
    }

    private func findObjects(ofType type: Int32) -> [CK_OBJECT_HANDLE] {
        var objectType = CK_OBJECT_CLASS(type)
        var template = withUnsafeMutablePointer(to: &objectType) { pointer in
            CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_CLASS),
                         pValue: pointer,
                         ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: pointer.pointee)))
        }

        var rv = C_FindObjectsInit(self.session, &template, 1)
        guard rv == CKR_OK else {
            return []
        }
        defer {
            C_FindObjectsFinal(self.session)
        }

        var count: CK_ULONG = 0
        let maxCount: CK_ULONG = 16
        var objects: [CK_OBJECT_HANDLE] = []
        repeat {
            var handles: [CK_OBJECT_HANDLE] = Array(repeating: 0x00, count: Int(maxCount))

            rv = C_FindObjects(self.session, &handles, maxCount, &count)
            guard rv == CKR_OK else {
                return []
            }

            objects += handles.prefix(Int(count))
        } while count == maxCount

        return objects
    }

    private func findObject(ofType type: Int32, byId id: Data) -> CK_OBJECT_HANDLE? {
        var objectType = CK_OBJECT_CLASS(type)
        let classAttr = withUnsafeMutablePointer(to: &objectType) { pointer in
            CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_CLASS),
                         pValue: pointer,
                         ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: pointer.pointee)))
        }

        var idArray: [UInt8] = Array(id)
        let ckaIDAttr = withUnsafeMutablePointer(to: &idArray[0]) { [length = idArray.count] pointer in
            CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_ID),
                         pValue: pointer,
                         ulValueLen: CK_ULONG(length))
        }
        var template: [CK_ATTRIBUTE] = [classAttr, ckaIDAttr]

        var rv = C_FindObjectsInit(self.session, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }
        defer {
            C_FindObjectsFinal(self.session)
        }

        // To check that object exists and is unique, try to find at least 2 ones.
        // If there are more than 1 object with same CKA_ID - it's pkcs11 standard violation.
        // Ignore thoose objects.
        var foundObjectsCount: CK_ULONG = 0
        var objects: [CK_OBJECT_HANDLE] = [CK_OBJECT_HANDLE(NULL_PTR), CK_OBJECT_HANDLE(NULL_PTR)]

        rv = C_FindObjects(self.session, &objects, CK_ULONG(objects.count), &foundObjectsCount)
        guard rv == CKR_OK else {
            return nil
        }

        guard foundObjectsCount == 1 else {
            return nil
        }

        return objects[0]
    }
}
