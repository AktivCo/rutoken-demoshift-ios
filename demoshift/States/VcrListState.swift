//
//  VcrListState.swift
//  demoshift
//
//  Created by Андрей Трифонов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


class VcrListState: ObservableObject {
    @Published var vcrs = [VcrInfo]()
}

struct VcrInfo: Identifiable {
    let id = UUID()
    let name: String
    let isActive = true
}
