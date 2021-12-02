//
//  VCRCard.swift
//  demoshift
//
//  Created by Vova Badyaev on 01.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct VCRCard: View {
    let name: String
    let isActive: Bool

    init(name: String, isActive: Bool) {
        self.name = name
        self.isActive = isActive
    }

    var body: some View {
        HStack(alignment: .center) {
            Image(isActive ? "vcr-icon-active" : "vcr-icon-inactive")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(16)
            Spacer()
            Text(name)
                .fontWeight(isActive ? .semibold : .thin)
                .padding(.horizontal)
        }
        .frame(height: 160)
        .background(Color("listitem-background"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 2.5, y: 2.5)
    }
}
