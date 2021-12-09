//
//  QrCode.swift
//  demoshift
//
//  Created by Александр Иванов on 10.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct QrCode: View {
    let qrCode: Image
    let isBlur: Bool

    var body: some View {
        qrCode
            .resizable()
            .scaledToFit()
            .blur(radius: isBlur ? 3 : 0)
            .background(Color(red: 0.8, green: 0.8, blue: 0.8).scaleEffect(1.1))
            .frame(maxHeight: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4))
            .padding()
    }
}
