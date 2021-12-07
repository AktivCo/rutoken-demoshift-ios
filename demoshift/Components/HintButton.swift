//
//  HintButton.swift
//  demoshift
//
//  Created by Александр Иванов on 29.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct HintButton<Content: View>: View {
    @State private var isHintPresented = false
    @ViewBuilder let popoverView: Content

    var body: some View {
        Button {
            isHintPresented.toggle()
        } label: {
            Image(systemName: "questionmark.circle.fill")
        }
        .foregroundColor(Color("text-blue"))
        .popover(isPresented: $isHintPresented) {
            popoverView
        }
    }
}
