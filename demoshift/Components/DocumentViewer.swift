//
//  DocumentViewer.swift
//  demoshift
//
//  Created by Pavel Kamenov on 27.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import PDFKit
import SwiftUI


struct DocumentViewer: UIViewRepresentable {
    @Binding var wrappedUrl: AccessedUrl?
    @State var pdfView = PDFView()

    func makeUIView(context: Context) -> PDFView {
        if let wrappedUrl = self.wrappedUrl {
            pdfView.document = PDFDocument(url: wrappedUrl.url)
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let wrappedUrl = self.wrappedUrl {
            self.pdfView.document = PDFDocument(url: wrappedUrl.url)
            pdfView.pageShadowsEnabled = true
            pdfView.autoScales = true
            pdfView.displayBox = .artBox
        } else {
            self.pdfView.document = nil
        }
    }
}
