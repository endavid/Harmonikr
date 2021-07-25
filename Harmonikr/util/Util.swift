//
//  Util.swift
//  Harmonikr
//
//  Created by David Gavilan on 2021/07/05.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif

// https://docs.swift.org/swift-book/ReferenceManual/Expressions.html
// https://stackoverflow.com/a/24402688/1765629
func logFunctionName(file: String = #file, fn: String = #function) {
    #if DEBUG
    let base = (file as NSString).lastPathComponent
    NSLog("\(base): \(fn)")
    #endif
}

func logDebug(_ text: String) {
    #if DEBUG
    NSLog(text)
    #endif
}

func openURL(_ urlString: String) {
    guard let url = URL(string: urlString) else {
        NSLog("Bad URL: \(urlString)")
        return
    }
    #if os(iOS)
    if #available(iOS 10.0, *) {
        UIApplication.shared.open(url, options: [:]) { success in
            if (!success) {
                NSLog("Failed to open URL: \(urlString)")
            }
        }
    } else {
        UIApplication.shared.openURL(url)
    }
    #else
    if !NSWorkspace.shared.open(url) {
        NSLog("Failed to open URL: \(urlString)")
    }
    #endif
}
