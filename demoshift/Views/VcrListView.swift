//
//  VcrListView.swift
//  demoshift
//
//  Created by Александр Иванов on 21.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct VcrListView: View {
    var body: some View {
        List {
            VCRCard(name: "iPhone (Sasha) - VCR", isActive: false)
            VCRCard(name: "iPhone (Masha) - VCR", isActive: true)
            VCRCard(name: "iPhone (Ragnaros) - VCR", isActive: false)
            VCRCard(name: "iPhone (Stas) - VCR", isActive: true)
            VCRCard(name: "iPhone (SAS) - VCR", isActive: false)
        }
    }
}
