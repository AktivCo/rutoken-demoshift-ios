//
//  Cert.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Foundation

class Cert {
    let id: Data
    let body: Data

    init?(fromHandle handle: CK_OBJECT_HANDLE, inSession session: CK_SESSION_HANDLE) {
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

        self.id = Data(buffer: UnsafeBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self), count: Int(template[0].ulValueLen)))
        self.body = Data(buffer: UnsafeBufferPointer(start: template[1].pValue.assumingMemoryBound(to: UInt8.self), count: Int(template[1].ulValueLen)))
    }
}
