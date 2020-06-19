//
//  TextFieldWithFloatingLabel.swift
//  demobsnk-swui
//
//  Created by Андрей Трифонов on 17.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct TextFieldWithFloatingLabel: View {
    let placeHolder: String
    @Binding var text: String

    var body: some View {
        let binding = Binding<String>(get: {
            self.text
        }, set: {
            let newText = $0
            withAnimation(.easeIn(duration: 0.1)) {
                self.text = newText
            }
        })

        return VStack {
            ZStack {
                HStack {
                    Text(self.placeHolder)
                        .font(self.text.isEmpty ? .body : .caption)
                        .foregroundColor(self.text.isEmpty ? Color(.systemGray2) : Color("text-blue"))
                        .offset(x: 0, y: self.text.isEmpty ? 0 : -20)
                    Spacer()
                }
                SecureField("", text: binding)
            }
            Divider()
                .frame(height: 1)
                .background(Color("text-blue"))
        }
    }
}

