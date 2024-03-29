//
//  AddVcrState.swift
//  demoshift
//
//  Created by Александр Иванов on 08.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine
import UIKit


class AddVcrState: ObservableObject {
    @Published var qrCode: UIImage?
    @Published var isBlurQr = true
    @Published var currentTime: CGFloat = 0.0
}
