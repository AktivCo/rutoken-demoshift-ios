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
        self.iconName = interfaces.contains(.BT) ? "ble" : "usb"
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(iconName)
                .resizable()
                .frame(width: 90, height: 90)
                .aspectRatio(contentMode: .fit)
                .padding(.vertical, 8)
                .padding(.leading, 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(modelName.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(modelName == .unsupported ? Color("text-gray") : nil)
                    .padding(.top, 10)
                Spacer()
                Text(modelName == .unsupported ? "Приложение работает только с Рутокен ЭЦП 2.0 и 3.0" : "Серийный номер")
                    .font(.system(size: 16).weight(.light))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color("text-gray"))
                    .padding(.bottom, modelName == .unsupported ? 10 : 4)
                if modelName != .unsupported {
                    Text(serial)
                        .font(.system(size: 16).weight(.light))
                        .foregroundColor(Color("text-gray"))
                        .padding(.bottom, 10)
                }
            }
            .padding(.leading, 16)
            Spacer()
        }
        .background(Color("listitem-background"))
        .cornerRadius(30)
    }
}
