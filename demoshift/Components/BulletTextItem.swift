//
//  BulletTextItem.swift
//  demoshift
//
//  Created by Александр Иванов on 30.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct BulletTextItem: View {
    let bullet: String
    let text: String

    var body: some View {
        HStack(alignment: .top) {
            Text(bullet)
                .font(.system(.body, design: .monospaced))
            Spacer()
                .fixedSize()
            Text(text)
                .padding(.leading)
        }
    }
}
