//
//  Util.swift
//  Harmonikr
//
//  Created by David Gavilan on 2021/07/05.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import Foundation

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

