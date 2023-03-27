//
//  UserCard.swift
//  demoshift
//
//  Created by Pavel Kamenov on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI


struct UserCard: View {
    @State private var offset = 0.0
    let maxTranslation = -72.0

    let name: String
    let position: String
    let company: String
    let expired: String

    let selectUser: (() -> Void)
    let removeUser: (() -> Void)

    init(user: User, selectUser: @escaping (() -> Void), removeUser: @escaping (() -> Void)) {
        self.name = user.name
        self.position = user.position
        self.company = user.company
        self.expired = user.expired

        self.selectUser = selectUser
        self.removeUser = removeUser
    }

    var body: some View {
        VStack(spacing: 0) {
            userInfo()
                .onTapGesture {
                    if offset == 0.0 {
                        selectUser()
                    } else {
                        offset = 0.0
                    }
                }
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .local)
                        .onChanged {
                            let translation = $0.translation.width
                            withAnimation {
                                if translation < 0 {
                                    offset = max(translation, maxTranslation)
                                } else {
                                    offset = 0
                                }
                            }
                        }
                        .onEnded {
                            let translation = $0.translation.width
                            withAnimation {
                                if translation < maxTranslation/2 {
                                    offset = maxTranslation
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
                .background(removeButton())
        }
        .cornerRadius(20)
        .shadow(radius: 5)
    }

    private func field(caption: String, text: String) -> some View {
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

    private func userInfo() -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .fontWeight(.semibold)
                    .font(.headline)

                field(caption: "Должность", text: position)
                field(caption: "Организация", text: company)
                field(caption: "Сертификат истекает", text: expired)
            }
            .padding(.vertical)
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(Color("listitem-background"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func removeButton() -> some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("Удалить")
                    .foregroundColor(.white)
                    .font(.system(size: 15))
                    .padding(6)
            }
            .frame(maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red)
        .cornerRadius(20)
        .onTapGesture { removeUser() }
    }
}
