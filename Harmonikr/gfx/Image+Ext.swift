//
//  Image+Ext.swift
//  Harmonikr
//
//  Created by David Gavilan on 25/07/2021.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import AppKit

extension NSImage {
    func trim(rect: CGRect) -> NSImage {
        // https://stackoverflow.com/a/56622501/1765629
        let result = NSImage(size: rect.size)
        result.lockFocus()
        let destRect = CGRect(origin: .zero, size: result.size)
        self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)
        result.unlockFocus()
        return result
    }
}
