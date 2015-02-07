//
//  Document.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/4/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    var imgIrradiance : CGImageRef!
    var imgCubemap: CGImageRef!
    var sphereMap : SphereMap!
    var cubeMap: CubeMap!
    @IBOutlet weak var imgViewIrradiance: NSImageView!
    @IBOutlet weak var imgViewCubemap: NSImageView!
    // cubemap outlets
    @IBOutlet weak var imgViewNegativeX: NSImageView!
    @IBOutlet weak var imgViewPositiveX: NSImageView!
    @IBOutlet weak var imgViewPositiveZ: NSImageView!
    @IBOutlet weak var imgViewNegativeZ: NSImageView!
    @IBOutlet weak var imgViewPositiveY: NSImageView!
    @IBOutlet weak var imgViewNegativeY: NSImageView!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
        sphereMap = SphereMap()
        cubeMap = CubeMap()
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
    
    /// Initialization code that needs the instantiated IBOutlets (before this function is called, they are still nil!)
    override func awakeFromNib() {
        updateImgIrradiance()
        updateImgCubemap()
    }
    
    // ref: https://gist.github.com/irskep/e560be65163efcb04115
    func updateImgIrradiance() {
        var rgb = CGColorSpaceCreateDeviceRGB();
        let bufferLength = sphereMap.getBufferLength()
        let provider = CGDataProviderCreateWithData(nil, sphereMap.imgBuffer, bufferLength, nil)
        var bitmapInfo:CGBitmapInfo = .ByteOrderDefault;
        // with alpha
        // bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.Last.rawValue)
        imgIrradiance = CGImageCreate(sphereMap.width, sphereMap.height, 8, 8 * sphereMap.bands, sphereMap.width * sphereMap.bands, rgb, bitmapInfo, provider, nil /*decode*/, false /*shouldInterpolate*/, kCGRenderingIntentDefault)
        imgViewIrradiance.image = NSImage(CGImage: imgIrradiance, size: NSZeroSize)
    }
    
    func updateImgCubemap() {
        var rgb = CGColorSpaceCreateDeviceRGB();
        let bufferLength = cubeMap.getBufferLength()
        let provider = CGDataProviderCreateWithData(nil, cubeMap.imgBuffer, bufferLength, nil)
        var bitmapInfo:CGBitmapInfo = .ByteOrderDefault;
        imgCubemap = CGImageCreate(cubeMap.width * cubeMap.sides, cubeMap.height, 8, 8 * cubeMap.bands, cubeMap.width * cubeMap.bands * cubeMap.sides, rgb, bitmapInfo, provider, nil /*decode*/, false /*shouldInterpolate*/, kCGRenderingIntentDefault)
        imgViewCubemap.image = NSImage(CGImage: imgCubemap, size: NSZeroSize)
        
    }

    @IBAction func computeHarmonics(sender: AnyObject) {
        println("Compute!")
    }
    

    @IBAction func inferCubemap(sender: AnyObject) {
        println("Infer")
        let imgNegX = imgViewNegativeX.image
        let imgPosX = imgViewPositiveX.image
        let imgNegZ = imgViewNegativeZ.image
        let imgPosZ = imgViewPositiveZ.image
        let imgNegY = imgViewNegativeY.image
        let imgPosY = imgViewPositiveY.image

        // if all are set, just copy them as sides of the cubemap
        if imgNegX != nil && imgPosX != nil && imgNegZ != nil && imgPosZ != nil && imgNegY != nil && imgPosY != nil {
            cubeMap.setFace(0, image: imgNegX!)
            cubeMap.setFace(1, image: imgPosZ!)
            cubeMap.setFace(2, image: imgPosX!)
            cubeMap.setFace(3, image: imgNegZ!)
            cubeMap.setFace(4, image: imgPosY!)
            cubeMap.setFace(5, image: imgNegY!)
            updateImgCubemap()
        }
    }
}

