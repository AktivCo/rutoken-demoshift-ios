//
//  ShareView.swift
//  demoshift
//
//  Created by Pavel Kamenov on 02.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI
import UIKit


struct ShareView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: self.activityItems, applicationActivities: nil)
        vc.excludedActivityTypes = [.addToReadingList, .assignToContact, .saveToCameraRoll, .markupAsPDF]
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
