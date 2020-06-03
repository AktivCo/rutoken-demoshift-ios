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
        Group {
            Text(caption)
                .font(.system(size: 20))
                .padding(.bottom, 2)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray))
                .padding(.horizontal, 10)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .fontWeight(.semibold)
                .font(.system(size: 20))

            field(caption: "Должность", text: position)
            field(caption: "Организация", text: company)
            field(caption: "Сертификат истекает", text: expired)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding()
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
