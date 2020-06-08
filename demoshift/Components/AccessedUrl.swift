//
//  AccessedUrl.swift
//  demoshift
//
//  Created by Pavel Kamenov on 11.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Foundation

class AccessedUrl: NSObject {
    let url: URL

    var didAccessStore: Bool = false

    init?(_ url: URL?) {
        guard let u = url else {
            return nil
        }

        self.url = u
        self.didAccessStore = self.url.startAccessingSecurityScopedResource()
    }

    deinit {
        if self.didAccessStore {
            self.url.stopAccessingSecurityScopedResource()
        }
    }
}
