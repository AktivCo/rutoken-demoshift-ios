//
//  Sharables.swift
//  demoshift
//
//  Created by Pavel Kamenov on 08.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import UIKit

class SharableSignature: NSObject, UIActivityItemSource {
    let rawSignature: String
    let cmsFile: URL

    init(rawSignature: String, cmsFile: URL) {
        self.rawSignature = rawSignature
        self.cmsFile = cmsFile
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.cmsFile
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case UIActivity.ActivityType.copyToPasteboard:
            return self.rawSignature
        default:
            return self.cmsFile
        }
    }

    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return UIImage(named: "app-icon")
    }
}

class SharableDocument: NSObject, UIActivityItemSource {
    let signedFile: URL

    init(signedFile: URL) {
        self.signedFile = signedFile
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.signedFile
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case UIActivity.ActivityType.copyToPasteboard:
            return nil
        default:
            return self.signedFile
        }
    }
}
