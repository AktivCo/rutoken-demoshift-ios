//
//  LoadingIndicator.swift
//  demoshift
//
//  Created by Андрей Трифонов on 05.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct LoadingIndicator: View {
    @State private var rotationToggle = false
    @State private var startPointToggle = false

    var body: some View {
        VStack {
            Circle()
                .trim(from: self.startPointToggle ? 0.05 : 0.95, to: 1)
                .stroke(Color("text-blue"), lineWidth: 5)
                .foregroundColor(.white)
                .rotationEffect(.degrees(self.rotationToggle ? 180 : 540))
                .onAppear(perform: {
                    withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: true)) {
                        self.startPointToggle.toggle()
                    }
                    withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                        self.rotationToggle.toggle()
                    }
            })
        }
    }
}
