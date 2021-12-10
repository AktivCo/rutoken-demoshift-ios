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

    var body: some View {
        qrCode
            .resizable()
            .scaledToFit()
            .frame(maxHeight: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4)).scaleEffect(0.95)
    }
}
