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

class Token: Identifiable {
    let slot: CK_SLOT_ID
    let serial: String
    private(set) var currentInterface: TokenInterface!
    private(set) var supportedInterfaces: [TokenInterface]!
    let modelName: TokenModelName

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

        guard let decimalSerial = Int(serial.trimmingCharacters(in: .whitespacesAndNewlines), radix: 16) else {
            return nil
        }
        self.serial = String(format: "%0.10d", decimalSerial)

        var extendedTokenInfo = CK_TOKEN_INFO_EXTENDED()
        extendedTokenInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: extendedTokenInfo))
        rv = C_EX_GetTokenInfoExtended(slot, &extendedTokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        self.modelName = TokenModelName(tokenInfo.hardwareVersion, tokenInfo.firmwareVersion, extendedTokenInfo.ulTokenClass)

        rv = C_OpenSession(self.slot, CK_FLAGS(CKF_SERIAL_SESSION), nil, nil, &self.session)
        guard rv == CKR_OK else {
            return nil
        }

        guard let (currentInterface, supportedInterfaces) = getTokenInterfaces() else {
            return nil
        }

        guard let interface = TokenInterface(currentInterface) else {
            return nil
        }

        self.currentInterface = interface
        self.supportedInterfaces = [TokenInterface](bits: supportedInterfaces)
    }

    func login(pin: String) throws {
        do {
            var rawPin: [UInt8] = Array(pin.utf8)
            let rv = C_Login(self.session, CK_USER_TYPE(CKU_USER), &rawPin, CK_ULONG(rawPin.count))
            guard rv == CKR_OK || rv == CKR_USER_ALREADY_LOGGED_IN else {
                switch rv {
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

    func logout() {
        C_Logout(self.session)
    }

    func enumerateCerts() throws -> [Cert] {
        do {
            var certs: [Cert] = []
            let objects = try findObjects((CK_OBJECT_CLASS(CKO_CERTIFICATE), CKA_CLASS))
            for obj in objects {
                guard let cert = Cert.makeCert(fromHandle: obj, inSession: self.session) else {
                    continue
                }

                // Check whether corresponding private key exists
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

    func cmsSign(_ document: Data, withCert cert: Cert) throws -> String {
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

                guard let wrappedSession = rt_eng_p11_session_wrap(functionListPointer, self.session, 0, nil) else {
                    throw TokenError.generalError
                }
                defer {
                    rt_eng_p11_session_free(wrappedSession)
                }

                guard let evpPKey = rt_eng_p11_key_pair_wrap(wrappedSession, privateKey, publicKey) else {
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

    private func findObjects(_ attributes: (CK_ULONG, UInt)...) throws -> [CK_OBJECT_HANDLE] {
        var values = [CK_ULONG]()
        var template = attributes.map { value, type in
            values.append(value)
            return withUnsafeMutablePointer(to: &(values[values.endIndex - 1])) { pointer in
                CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(type),
                             pValue: pointer,
                             ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: pointer.pointee)))
            }
        }
        var rv = C_FindObjectsInit(self.session, &template, CK_ULONG(template.count))
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

    private func getTokenInterfaces() -> (CK_ULONG, CK_ULONG)? {
        guard let handle =  try? findObjects((CK_OBJECT_CLASS(CKO_HW_FEATURE), CKA_CLASS),
                                             (CK_HW_FEATURE_TYPE(CKH_VENDOR_TOKEN_INFO), CKA_HW_FEATURE_TYPE)).first else {
            return nil
        }

        let valueSize: CK_ULONG = 0
        let currentInterfaceAttr = CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_VENDOR_CURRENT_TOKEN_INTERFACE),
                                                pValue: nil,
                                                ulValueLen: valueSize)
        let supportedInterfaceAttr = CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_VENDOR_SUPPORTED_TOKEN_INTERFACE),
                                                  pValue: nil,
                                                  ulValueLen: valueSize)

        var template = [currentInterfaceAttr, supportedInterfaceAttr]

        var rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        for i in 0..<template.count {
            template[i].pValue = UnsafeMutableRawPointer.allocate(byteCount: Int(template[i].ulValueLen), alignment: 1)
        }
        defer {
            for i in 0..<template.count {
                template[i].pValue.deallocate()
            }
        }

        rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        return (UnsafeRawBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                       count: Int(template[0].ulValueLen)).load(as: CK_ULONG.self),
                UnsafeRawBufferPointer(start: template[1].pValue.assumingMemoryBound(to: UInt8.self),
                                       count: Int(template[1].ulValueLen)).load(as: CK_ULONG.self))
    }

    private func findObject(ofType type: UInt, byId id: Data) throws -> CK_OBJECT_HANDLE? {
        var objectType = CK_OBJECT_CLASS(type)

        let objectTypePointer = UnsafeMutablePointer<UInt>.allocate(capacity: MemoryLayout.size(ofValue: objectType))
        defer {
            objectTypePointer.deallocate()
        }
        objectTypePointer.initialize(from: &objectType, count: MemoryLayout.size(ofValue: objectType))

        let classAttr = CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_CLASS),
                                     pValue: objectTypePointer,
                                     ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: objectType)))

        var idArray: [UInt8] = Array(id)

        let ckaIDPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: idArray.count)
        defer {
            ckaIDPointer.deallocate()
        }
        ckaIDPointer.initialize(from: &idArray, count: idArray.count)

        let ckaIDAttr = CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_ID),
                                     pValue: ckaIDPointer,
                                     ulValueLen: CK_ULONG(idArray.count))

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
