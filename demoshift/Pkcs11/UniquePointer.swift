//
//  UniquePointer.swift
//  demoshift
//
//  Created by Pavel Kamenov on 05.06.2023.
//  Copyright © 2023 Aktiv Co. All rights reserved.
//

import Foundation


class UniquePointer {
    fileprivate var pointer: OpaquePointer?
    private let free: ((OpaquePointer) -> Void)

    init(_ pointer: OpaquePointer? = nil, free: @escaping (OpaquePointer) -> Void) {
        self.pointer = pointer
        self.free = free
    }

    func reset(_ p: OpaquePointer?) {
        pointer = p
    }

    deinit {
        guard let pointer else { return }
        free(pointer)
    }
}

extension OpaquePointer {
    init?(_ p: UniquePointer) {
        guard let op = p.pointer else {
            return nil
        }
        self = op
    }
}
