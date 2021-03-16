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
    case generalError
    case certNotFound
    case keyPairNotFound
    case tokenDisconnected
}

class Token {
    enum TokenType {
        case NFC
        case BT
    }

    let slot: CK_SLOT_ID
    let serial: String
    let type: TokenType

    private var session = CK_SESSION_HANDLE(NULL_PTR)

    init?(slot: CK_SLOT_ID) {
        self.slot = slot

        var tokenInfo = CK_TOKEN_INFO()
        var rv = C_GetTokenInfo(slot, &tokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        let mirror = Mirror(reflecting: tokenInfo.serialNumber)
        let arr = mirror.children.compactMap { $0.value as? UInt8 }

        guard arr.count == mirror.children.count else {
            return nil
        }

        guard let serial = String(bytes: arr, encoding: .utf8) else {
            return nil
        }

        self.serial = serial.trimmingCharacters(in: .whitespacesAndNewlines)

        var extendedTokenInfo = CK_TOKEN_INFO_EXTENDED()
        extendedTokenInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: extendedTokenInfo))

        rv = C_EX_GetTokenInfoExtended(slot, &extendedTokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        switch Int32(extendedTokenInfo.ulTokenType) {
        case TOKEN_TYPE_RUTOKEN_ECPDUAL_BT:
            self.type = .BT
        case TOKEN_TYPE_RUTOKEN_ECP_NFC:
            self.type = .NFC
        default:
            return nil
        }

        rv = C_OpenSession(self.slot, CK_FLAGS(CKF_SERIAL_SESSION), nil, nil, &self.session)
        guard rv == CKR_OK else {
            return nil
        }
    }

    public func login(pin: String) throws {
        do {
            var rawPin: [UInt8] = Array(pin.utf8)
            let rv = C_Login(self.session, CK_USER_TYPE(CKU_USER), &rawPin, CK_ULONG(pin.count))
            guard rv == CKR_OK || rv == CKR_USER_ALREADY_LOGGED_IN else {
                switch Int32(rv) {
                case CKR_PIN_INCORRECT:
                    throw TokenError.incorrectPin
                case CKR_PIN_LOCKED:
                    throw TokenError.lockedPin
                default:
                    throw TokenError.generalError
                }
            }
        } catch let error {
            if TokenManager.shared.isConnected(token: self) {
                throw error
            }
            throw TokenError.tokenDisconnected
        }
    }

    public func enumerateCerts() throws -> [Cert] {
        do {
            var certs: [Cert] = []
            let objects = try self.findObjects(ofType: CKO_CERTIFICATE)
            for obj in objects {
                guard let cert = Cert.makeCert(fromHandle: obj, inSession: self.session) else {
                    continue
                }

                //Check whether corresponding private key exists
                guard try findObject(ofType: CKO_PRIVATE_KEY, byId: cert.id) != nil else {
                    continue
                }
                certs.append(cert)
            }
            return certs
        } catch let error {
            if TokenManager.shared.isConnected(token: self) {
                throw error
            }
            throw TokenError.tokenDisconnected
        }
    }

    public func cmsSign(_ document: Data, withCert cert: Cert) throws -> String {
        do {
            var encodedCms: String = ""

            guard let privateKey = try? findObject(ofType: CKO_PRIVATE_KEY, byId: cert.id),
            let publicKey = try? findObject(ofType: CKO_PUBLIC_KEY, byId: cert.id) else {
                throw TokenError.keyPairNotFound
            }

            var functionList = CK_FUNCTION_LIST()
            try withUnsafeMutablePointer(to: &functionList) { pointer in
                var functionListPointer: UnsafeMutablePointer<CK_FUNCTION_LIST>? = pointer
                let rv = C_GetFunctionList(&functionListPointer)
                guard rv == CKR_OK else {
                    throw TokenError.generalError
                }

                var wrappedSession = rt_eng_p11_session_new(functionListPointer, self.session, 0, nil)
                guard wrappedSession.`self` != nil else {
                    throw TokenError.generalError
                }
                defer {
                    var temp = wrappedSession
                    withUnsafeMutablePointer(to: &wrappedSession) { ptr in
                        temp.vtable.pointee.free(ptr)
                    }
                }

                guard let evpPKey = rt_eng_new_p11_ossl_evp_pkey(wrappedSession, privateKey, publicKey) else {
                    throw TokenError.generalError
                }
                defer {
                    EVP_PKEY_free(evpPKey)
                }

                guard let bio = BIO_new(BIO_s_mem()) else {
                    throw TokenError.generalError
                }
                defer {
                    BIO_free(bio)
                }

                try document.withUnsafeBytes {
                    let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                    let res = BIO_write(bio, pointer, Int32(document.count))
                    if res != document.count {
                        throw TokenError.generalError
                    }
                }

                try cert.body.withUnsafeBytes {
                    var pointer: UnsafePointer<UInt8>? = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                    guard let x509 = d2i_X509(nil, &pointer, cert.body.count) else {
                        throw TokenError.generalError
                    }
                    defer {
                        X509_free(x509)
                    }

                    guard let cms = CMS_sign(x509, evpPKey, nil, bio, UInt32(CMS_BINARY | CMS_NOSMIMECAP | CMS_DETACHED)) else {
                        throw TokenError.generalError
                    }
                    defer {
                        CMS_ContentInfo_free(cms)
                    }

                    let cmsLength = i2d_CMS_ContentInfo(cms, nil)
                    var cmsData = Data(repeating: 0x00, count: Int(cmsLength))
                    cmsData.withUnsafeMutableBytes {
                        var pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        i2d_CMS_ContentInfo(cms, &pointer)
                    }

                    // Add EOL after every 64th symbol
                    let rawSignature = cmsData.base64EncodedString().enumerated().map { (idx, el) in
                        idx > 0 && idx % 64 == 0 ? ["\n", el] : [el]
                    }.joined()

                    encodedCms = "-----BEGIN CMS-----\n" + rawSignature + "\n-----END CMS-----"
                }
            }
            return encodedCms
        } catch let error {
            if TokenManager.shared.isConnected(token: self) {
                throw error
            }
            throw TokenError.tokenDisconnected
        }
    }

    private func findObjects(ofType type: Int32) throws -> [CK_OBJECT_HANDLE] {
        var objectType = CK_OBJECT_CLASS(type)
        var template = withUnsafeMutablePointer(to: &objectType) { pointer in
            CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_CLASS),
                         pValue: pointer,
                         ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: pointer.pointee)))
        }

        var rv = C_FindObjectsInit(self.session, &template, 1)
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }
        defer {
            C_FindObjectsFinal(self.session)
        }

        var count: CK_ULONG = 0
        // You can define your own number of required objects.
        let maxCount: CK_ULONG = 16
        var objects: [CK_OBJECT_HANDLE] = []
        repeat {
            var handles: [CK_OBJECT_HANDLE] = Array(repeating: 0x00, count: Int(maxCount))

            rv = C_FindObjects(self.session, &handles, maxCount, &count)
            guard rv == CKR_OK else {
                throw TokenError.generalError
            }

            objects += handles.prefix(Int(count))
        } while count == maxCount

        return objects
    }

    private func findObject(ofType type: Int32, byId id: Data) throws -> CK_OBJECT_HANDLE? {
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
            throw TokenError.generalError
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
            throw TokenError.generalError
        }

        guard foundObjectsCount == 1 else {
            return nil
        }

        return objects[0]
    }
}
