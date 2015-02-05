//
//  Document.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/4/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    let irradianceWidth     : UInt = 32
    let irradianceHeight    : UInt = 32
    let irradianceBands     : UInt = 3     ///< R,G,B
    var imgBuffer : Array<UInt8>!
    var imgIrradiance : CGImageRef!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
        let bufferLength : Int = (Int)(irradianceWidth * irradianceHeight * irradianceBands)
        imgBuffer = Array<UInt8>(count: bufferLength, repeatedValue: 0)
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    override func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }

    override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return false
    }
    
    override func awakeFromNib() {
        updateImgIrradiance()
    }
    
    func updateImgIrradiance() {
        var rgb = CGColorSpaceCreateDeviceRGB();
        let bufferLength = irradianceWidth * irradianceHeight * irradianceBands;
        let provider = CGDataProviderCreateWithData(nil, imgBuffer, bufferLength, nil)
        var bitmapInfo:CGBitmapInfo = .ByteOrderDefault;
        // with alpha
        // bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.Last.rawValue)
        imgIrradiance = CGImageCreate(irradianceWidth, irradianceHeight, 8, 8 * irradianceBands, irradianceWidth * irradianceBands, rgb, bitmapInfo, provider, nil /*decode*/, false /*shouldInterpolate*/, kCGRenderingIntentDefault)
        imgViewIrradiance.image = NSImage(CGImage: imgIrradiance, size: NSZeroSize)
    }

    @IBAction func computeHarmonics(sender: AnyObject) {
        println("Compute!")
    }
    
    @IBOutlet weak var imgViewIrradiance: NSImageView!

}

