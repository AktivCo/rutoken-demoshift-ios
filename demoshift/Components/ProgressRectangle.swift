//
//  ProgressRectangle.swift
//  demoshift
//
//  Created by Александр Иванов on 13.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct ProgressRectangle: View {
    let lineWidth = 15.0
    let state: CGFloat
    let color: UIColor

    var body: some View {
        RoundedRectangle(cornerRadius: lineWidth/2)
            .trim(from: 0, to: 1)
            .stroke(Color.gray, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(maxWidth: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4),
                   maxHeight: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4))
            .rotationEffect(.init(degrees: -90))
            .scaledToFit()

        RoundedRectangle(cornerRadius: lineWidth/2)
            .trim(from: 0, to: 1-state)
            .stroke(Color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            .frame(maxWidth: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4),
                   maxHeight: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4))
            .rotationEffect(.init(degrees: -90))
            .scaledToFit()
    }
}
