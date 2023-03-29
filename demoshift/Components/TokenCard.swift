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
        self.iconName = interfaces.contains(.BT) ? "ble" : interfaces.contains(.SC) ? "smartcard" : "usb"
    }

    var body: some View {
        HStack(spacing: 0) {
            if modelName == .unsupported {
                VStack(alignment: .leading, spacing: 0) {
                    Text(modelName.rawValue)
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("Приложение работает только с Рутокен ЭЦП 2.0 и 3.0")
                        .font(.system(size: 16).weight(.light))
                }
                .padding(.horizontal, 56)
                .padding(.vertical, 20)
                .foregroundColor(Color("text-gray"))
            } else {
                Image(iconName)
                    .resizable()
                    .frame(width: 90, height: 90)
                    .aspectRatio(contentMode: .fit)
                    .padding(.vertical, 8)
                    .padding(.leading, 8)
                VStack(alignment: .leading, spacing: 0) {
                    Text(modelName.rawValue)
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("Серийный номер\n\(serial)")
                        .font(.system(size: 16).weight(.light))
                        .foregroundColor(Color("text-gray"))
                }
                .padding(.vertical, 10)
                .padding(.leading, 18)
                Spacer()
            }
        }
        .frame(height: 106)
        .background(Color("listitem-background"))
        .cornerRadius(30)
    }
}
