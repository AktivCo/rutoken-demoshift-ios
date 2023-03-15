//
//  TokenCard.swift
//  demoshift
//
//  Created by Vova Badyaev on 24.11.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

import SwiftUI


struct TokenCard: View {
    let modelName: TokenModelName
    let serial: String
    let currentInterface: TokenInterface
    let interfaces: [TokenInterface]
    let iconName: String

    init(modelName: TokenModelName, serial: String, currentInterface: TokenInterface, interfaces: [TokenInterface]) {
        self.modelName = modelName
        self.serial = serial
        self.currentInterface = currentInterface
        self.interfaces = interfaces

        if interfaces.contains(.BT) {
            self.iconName = "ble"
        } else {
            self.iconName = "usb"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(iconName)
                .resizable()
                .frame(width: 50, height: 50)
                .aspectRatio(contentMode: .fit)
                .padding(.vertical, 28)
                .padding(.leading, 28)
            VStack(alignment: .leading, spacing: 0) {
                Text(modelName.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(modelName == .unsupported ? Color("text-gray") : nil)
                    .padding(.top, modelName == .unsupported ? 28 : 27)
                Spacer()
                Text(modelName == .unsupported ? "Приложение работает только с Рутокен ЭЦП 2.0 и 3.0" : "Серийный номер: \(serial)")
                    .font(.system(size: 16).weight(.light))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color("text-gray"))
            }
            .padding(.bottom, modelName == .unsupported ? 5 : 27)
            .padding(.leading, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 106, alignment: .leading)
        .background(Color("listitem-background"))
        .cornerRadius(30)
    }
}
