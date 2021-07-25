//
//  Image+Ext.swift
//  Harmonikr
//
//  Created by David Gavilan on 25/07/2021.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import AppKit

extension NSImage {
    func cropping(to rect: CGRect) -> NSImage {
        // https://stackoverflow.com/a/68521084/1765629
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let imageRef = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
            return NSImage(size: rect.size)
        }
        guard let crop = imageRef.cropping(to: rect) else {
            return NSImage(size: rect.size)
        }
        return NSImage(cgImage: crop, size: NSZeroSize)
    }
}
