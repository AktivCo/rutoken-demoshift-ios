//
//  UserView.swift
//  demoshift
//
//  Created by Pavel Kamenov on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

class User: Identifiable {
    let name: String
    let position: String
    let company: String
    let expired: String

    let tokenSerial: String

    let certID: Data
    let certBody: Data

    init(fromCert cert: Cert, tokenSerial: String) {
        self.name = cert.commonName
        self.position = cert.position
        self.company = cert.companyName
        self.expired = cert.expired

        self.tokenSerial = tokenSerial

        self.certID = cert.id
        self.certBody = cert.body
    }
}

struct UserView: View {
    let name: String
    let position: String
    let company: String
    let expired: String

    init(user: User) {
        self.name = user.name
        self.position = user.position
        self.company = user.company
        self.expired = user.expired
    }

    func field(caption: String, text: String) -> some View {
        VStack(alignment: .leading) {
            Text(caption)
                .font(.caption)
                .foregroundColor(Color("blue-text"))
                .padding(.bottom, 4)
            Text(text)
                .font(.subheadline)
        }
        .padding(.top, 16)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .fontWeight(.semibold)
                .font(.headline)

            field(caption: "Должность", text: position)
            field(caption: "Организация", text: company)
            field(caption: "Сертификат истекает", text: expired)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
        .padding(.horizontal, 24)
        .background(Color("listitem-background"))
        .cornerRadius(15)
        .shadow(color: Color(.systemGray), radius: 5, x: 0, y: 0)
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(user: User(fromCert: Cert(id: Data(), body: Data()), tokenSerial: "123"))
    }
}
