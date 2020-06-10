//
//  DocumentViewer.swift
//  demoshift
//
//  Created by Pavel Kamenov on 27.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI
import PDFKit

struct DocumentViewer: UIViewRepresentable {
    let url: URL
    init(_ url: URL) {
        self.url = url
    }

    func makeUIView(context: Context) -> UIView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.pageShadowsEnabled = true
        pdfView.autoScales = true
        pdfView.displayBox = .artBox
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
