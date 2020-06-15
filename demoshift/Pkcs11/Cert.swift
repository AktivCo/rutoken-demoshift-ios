//
//  Cert.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Foundation

fileprivate extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

class Cert: Identifiable {
    let id: Data
    let body: Data

    private(set) var commonName: String = "<не задано>"
    private(set) var position: String = "<не задано>"
    private(set) var companyName: String = "<не задано>"
    private(set) var expired: String = "<не задано>"
    private(set) var inn: String = "<не задано>"
    private(set) var ogrn: String = "<не задано>"
    private(set) var alg: String = "<не задано>"

    static func makeCert(fromHandle handle: CK_OBJECT_HANDLE, inSession session: CK_SESSION_HANDLE) -> Cert? {
        let valueSize: CK_ULONG = 0
        var template: [CK_ATTRIBUTE] = [
            CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_ID),
                         pValue: nil,
                         ulValueLen: valueSize),
            CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_VALUE),
                         pValue: nil,
                         ulValueLen: valueSize)
        ]

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
        let id = Data(buffer: UnsafeBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self), count: Int(template[0].ulValueLen)))
        let body = Data(buffer: UnsafeBufferPointer(start: template[1].pValue.assumingMemoryBound(to: UInt8.self), count: Int(template[1].ulValueLen)))

        return Cert(id: id, body: body)
    }

    init?(id: Data, body: Data) {
        self.id = id
        self.body = body

        guard (body.withUnsafeBytes { p -> Bool in
            var pointer = p.baseAddress?.assumingMemoryBound(to: UInt8.self)
            guard let x509 = d2i_X509(nil, &pointer, body.count) else {
                return false
            }
            defer {
                X509_free(x509)
            }

            self.commonName = getDataFromX509(x509, ForNID: NID_commonName) ?? "<не задано>"
            self.position = getDataFromX509(x509, ForNID: NID_title) ?? "<не задано>"
            self.companyName = getDataFromX509(x509, ForNID: NID_organizationName) ?? "<не задано>"
            self.inn = getDataFromX509(x509, ForNID: NID_INN) ?? "<не задано>"
            self.ogrn = getDataFromX509(x509, ForNID: NID_OGRN) ?? "<не задано>"
            self.expired = getNotAfterFromX509(x509) ?? "<не задано>"

            guard let alg = getKeyAlgFromX509(x509) else {
                return false
            }
            self.alg = alg
            return true
        }) else {
            return nil
        }
    }

    private func getKeyAlgFromX509(_ x509: OpaquePointer?) -> String? {
        guard let key = X509_get0_pubkey(x509) else {
            return nil
        }

        switch EVP_PKEY_base_id(key) {
        case NID_id_GostR3410_2001:
            return "ГОСТ Р 34.10-2001"
        case NID_id_GostR3410_2012_256:
            return "ГОСТ Р 34.10-2012 256"
        case NID_id_GostR3410_2012_512:
            return "ГОСТ Р 34.10-2012 512"
        default:
            return nil
        }
    }

    private func getNotAfterFromX509(_ x509: OpaquePointer?) -> String? {
        guard let body = x509 else {
            return nil
        }

        guard let asn1Time = X509_get0_notAfter(body) else {
            return nil
        }

        guard let genTime = ASN1_TIME_to_generalizedtime(asn1Time, nil) else {
            return nil
        }
        defer {
            ASN1_STRING_free(genTime)
        }

        guard let rawTime = ASN1_STRING_get0_data(genTime) else {
            return nil
        }

        // ASN1 generalized time looks like this: "20131114230046"
        //                                format:  YYYYMMDDHHMMSS
        //                               indices:  0123456789...
        // We use first 8 bytes to get our style date: DD.MM.YYYY
        let length = ASN1_STRING_length(genTime)
        guard length >= 8 else {
            return nil
        }
        let t = String(data: Data(bytes: rawTime, count: Int(length)), encoding: .utf8)!

        return "\(t[6...7]).\(t[4...5]).\(t[0...3])"
    }

    private func getDataFromX509(_ x509: OpaquePointer?, ForNID nid: Int32) -> String? {
        guard let body = x509 else {
            return nil
        }

        let len = X509_NAME_get_text_by_NID(X509_get_subject_name(body), nid, nil, 0) + 1
        guard len > 1 else {
            return nil
        }

        var data = Data(count: Int(len))
        data.withUnsafeMutableBytes {
            let pointer = $0.baseAddress?.assumingMemoryBound(to: Int8.self)
            X509_NAME_get_text_by_NID(X509_get_subject_name(x509), nid, pointer, len)
        }

        return String(data: data, encoding: .utf8)
    }
}
