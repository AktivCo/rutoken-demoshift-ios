//
//  TokenListState.swift
//  demoshift
//
//  Created by Vova Badyaev on 29.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


class TokenListState: ObservableObject {
    @Published var showCertListView = false
    @Published var showPinInputView = false
    @Published var selectedTokenSerial = ""
    @Published var selectedTokenType: TokenInterface = .NFC
    @Published var selectedTokenInterfaces = [TokenInterface]()
    @Published var selectedTokenCerts: [Cert] = []
    @Published var readers = [Reader]()
    @Published var tokens = [Token]()

    @Published var taskStatus = TaskStatus()
}
