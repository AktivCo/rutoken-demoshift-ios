//
//  SignState.swift
//  demoshift
//
//  Created by Vova Badyaev on 29.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


class SignState: ObservableObject {
    @Published var showPinInputView = false
    @Published var signatureToShare: SharableSignature?
    @Published var documentToShare: SharableDocument?
    @Published var readers = [Reader]()

    @Published var taskStatus = TaskStatus()
}
