//
//  UserCard.swift
//  demoshift
//
//  Created by Pavel Kamenov on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI


struct UserCard: View {
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
                .foregroundColor(Color("text-blue"))
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
        .cornerRadius(20)
        .shadow(radius: 5, x: 0, y: 0)
    }
}
