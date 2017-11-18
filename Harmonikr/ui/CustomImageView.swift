//
//  CustomImageView.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/27/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//
// Ref. http://nsnotfound.blogspot.co.uk/2007/08/nsimageview-and-image-filenames.html

import Cocoa

class CustomImageView: NSImageView {

    var localPath : String = ""
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let dragSucceeded = super.performDragOperation(sender)
        if !dragSucceeded {
            return false
        }
        if #available(OSX 10.13, *) {
            guard let filenamesXML = sender.draggingPasteboard().string(forType: .fileURL) else {
                return false
            }
            guard let data = filenamesXML.data(using: .utf8) else {
                return false
            }
            do {
                let filenames = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                guard let array = filenames as? NSArray else {
                    return false
                }
                localPath = array[0] as! String
                return true
            } catch let error {
                NSLog("performDragOperation: \(error.localizedDescription)")
                return false
            }
        } else {
            // Fallback on earlier versions
            return false
        }
    }
}
