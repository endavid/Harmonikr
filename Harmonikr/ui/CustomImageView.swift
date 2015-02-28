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
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let dragSucceeded = super.performDragOperation(sender)
        if dragSucceeded {
            let filenamesXML = sender.draggingPasteboard().stringForType(NSFilenamesPboardType)
            if filenamesXML != nil {
                var error : NSError?
                let data = filenamesXML!.dataUsingEncoding(NSUTF8StringEncoding)
                if data != nil {
                    let filenames : AnyObject! = NSPropertyListSerialization.propertyListWithData(data!, options: 0, format: nil, error: &error)
                    if error == nil && filenames != nil {
                        if let array = filenames as? NSArray {
                            localPath = array[0] as String
                        }
                    }
                }
            }
        }
        return dragSucceeded
    }
}
