//
//  CertCard.swift
//  demoshift
//
//  Created by Андрей Трифонов on 10.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct CertCard: View {
    let commonName: String
    let position: String
    let companyName: String
    let inn: String
    let ogrn: String
    let expired: String
    let alg: String

    let isDisabled: Bool

    init(cert: Cert, isDisabled: Bool) {
        self.commonName = cert.commonName
        self.position = cert.position
        self.companyName = cert.companyName
        self.inn = cert.inn
        self.ogrn = cert.ogrn
        self.expired = cert.expired
        self.alg = cert.alg

        self.isDisabled = isDisabled
    }

    var body: some View {
        VStack(alignment: .leading) {
            if self.isDisabled {
                Text("Уже зарегистрирован")
                .fontWeight(.semibold)
                .font(.headline)
                .foregroundColor(Color("red-text"))
                .padding(.bottom)
            }
            Text("\(commonName)")
                .fontWeight(.semibold)
                .font(.headline)
                .padding(.bottom)
            verticalField(caption: "Владелец", value: self.commonName)
            Text("\(position)")
                .font(.caption)
                .foregroundColor(Color("gray-text"))
                .padding(.bottom)
            verticalField(caption: "Организация", value: self.companyName)
            horizontalField(caption: "ИНН", value: self.inn)
            horizontalField(caption: "ОГРН", value: self.ogrn)
            HStack {
                verticalField(caption: "Алгоритм", value: self.alg)
                Spacer()
                verticalField(caption: "Истекает", value: self.expired)
            }
            .padding(.top)
        }
        .padding()
        .background(Color("listitem-background"))
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    func horizontalField(caption: String, value: String) -> some View {
        HStack {
            Text("\(caption)")
                .font(.caption)
                .foregroundColor(Color("gray-text"))
            Text("\(value)")
                .font(.caption)
                .foregroundColor(Color("gray-text"))
        }
    }

    func verticalField(caption: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text("\(caption)")
                .font(.caption)
                .foregroundColor(Color("blue-text"))
                .padding(.bottom, 4)
            Text("\(value)")
                .padding(.bottom, 2)
        }
    }
}
