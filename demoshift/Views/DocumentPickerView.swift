//
//  DocumentPickerView.swift
//  demoshift
//
//  Created by Pavel Kamenov on 08.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import MobileCoreServices
import SwiftUI


struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var wrappedUrl: AccessedUrl?

    func makeCoordinator() -> Coordinator {
        return DocumentPickerView.Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            self.parent.wrappedUrl = AccessedUrl(urls.first)
        }
    }
}
