//
//  Hint.swift
//  demoshift
//
//  Created by Александр Иванов on 20.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct Hint: View {
    let titlePopover: String
    let plainText: [String]
    let titleBulletText: String
    let bulletText: [String]

    var body: some View {
        ZStack {
            Color("sheet-background").edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                Text(titlePopover)
                    .font(.title)
                    .padding(.bottom)
                ForEach(plainText, id: \.self) {
                    Text($0)
                }
                Text(titleBulletText)
                    .padding(.vertical)
                ForEach(bulletText.indices, id: \.self) { i in
                    BulletTextItem(bullet: "\(i+1).", text: bulletText[i])
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .padding(.vertical, 40)
        }
    }
}
