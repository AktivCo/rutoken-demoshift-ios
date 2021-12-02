//
//  RoundedFilledButton.swift
//  demobsnk-swui
//
//  Created by Андрей Трифонов on 17.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI


struct RoundedFilledButton: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        RoundedFilledButton(configuration: configuration)
    }

    struct RoundedFilledButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.headline)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(isEnabled ? Color("button-text") : Color("button-text-disabled"))
                .background(isEnabled ? Color("button-background") : Color("button-background-disabled"))
                .cornerRadius(20)
        }
    }
}
