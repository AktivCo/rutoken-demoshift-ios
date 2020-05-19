//
//  RoundedFilledButton.swift
//  demobsnk-swui
//
//  Created by Андрей Трифонов on 17.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct RoundedFilledButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color("rutokenBlue"))
            .cornerRadius(16)
    }
}
