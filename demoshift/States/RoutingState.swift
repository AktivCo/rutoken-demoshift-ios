//
//  RoutingState.swift
//  demoshift
//
//  Created by Александр Иванов on 21.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


class RoutingState: ObservableObject {
    @Published var showVCRListView: Bool = false
    @Published var showAddVCRView: Bool = false
}
