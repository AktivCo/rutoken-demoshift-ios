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

    var body: some View {
        HStack(spacing: 0) {
            Image("usb")
                .frame(width: 50, height: 50)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(modelName == .unsupported ? Color("usb-icon-gray") : Color("usb-icon-red"))
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
