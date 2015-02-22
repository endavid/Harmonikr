//
//  Document.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/4/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Cocoa


/** Saves image to disk
*  @see http://stackoverflow.com/questions/1320988/saving-cgimageref-to-a-png-file
*/
func CGImageWriteToFile(image: CGImageRef, filename: NSURL) {
    let url = filename as CFURL
    let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil)
    CGImageDestinationAddImage(destination, image, nil);
    
    if !CGImageDestinationFinalize(destination) {
        println("Failed to write image to \(filename.absoluteString)")
    }
}

class Document: NSDocument, NSTableViewDataSource, NSTableViewDelegate {

    var imgIrradiance : CGImageRef!
    var imgCubemap: CGImageRef!
    var sphereMap : SphereMap!
    var cubeMap: CubeMap!
    var sphericalHarmonics: SphericalHarmonics?
    
    @IBOutlet weak var imgViewIrradiance: NSImageView!
    @IBOutlet weak var imgViewCubemap: NSImageView!
    // cubemap outlets
    @IBOutlet weak var imgViewNegativeX: NSImageView!
    @IBOutlet weak var imgViewPositiveX: NSImageView!
    @IBOutlet weak var imgViewPositiveZ: NSImageView!
    @IBOutlet weak var imgViewNegativeZ: NSImageView!
    @IBOutlet weak var imgViewPositiveY: NSImageView!
    @IBOutlet weak var imgViewNegativeY: NSImageView!
    @IBOutlet weak var textFieldNumBands: NSTextField!
    @IBOutlet weak var textFieldNumSamples: NSTextField!
    @IBOutlet weak var tableViewCoeffs: NSTableView!
    @IBOutlet weak var sliderPosYPercentage: NSSlider!
    @IBOutlet weak var sliderMapResolution: NSSlider!
    @IBOutlet weak var buttonRGBConversion: NSButton!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
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
        let power = sliderMapResolution.integerValue
        let numPixels = UInt(2 << power)
        sphereMap = SphereMap(w: numPixels, h: numPixels, negYr: sliderPosYPercentage.floatValue)
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
        imgCubemap = CGImageCreate(cubeMap.width * cubeMap.numFaces, cubeMap.height, 8, 8 * cubeMap.numBands, cubeMap.width * cubeMap.numBands * cubeMap.numFaces, rgb, bitmapInfo, provider, nil /*decode*/, false /*shouldInterpolate*/, kCGRenderingIntentDefault)
        imgViewCubemap.image = NSImage(CGImage: imgCubemap, size: NSZeroSize)
        // SH no longer valid
        sphericalHarmonics = nil
    }
    
    func updateSphericalHarmonics() {
        sphericalHarmonics = SphericalHarmonics(numBands: UInt(textFieldNumBands.integerValue), numSamples: UInt(textFieldNumSamples.integerValue))
        if buttonRGBConversion.state == NSOnState {
            // function to sample & convert to linear RGB
            let f = { (θ: Float, φ: Float) -> Vector3 in
                return colorRGBfromSRGB(self.cubeMap.polarSampler(θ: θ, φ: φ))
            }
            // compute spherical harmonics
            sphericalHarmonics!.projectPolarFn(f)
        } else {
            sphericalHarmonics!.projectPolarFn(cubeMap.polarSampler)
        }
        tableViewCoeffs.reloadData()
    }

    @IBAction func computeHarmonics(sender: AnyObject) {
        if sphericalHarmonics == nil {
            updateSphericalHarmonics()
        }
        let sh = sphericalHarmonics!
        var f = { (v: Vector3) -> Vector3 in
                return Clamp(v, 0, 1) * 255.0
            }
        if buttonRGBConversion.state == NSOnState {
            // function to sample & convert back to gamma RGB
            f = { (v: Vector3) -> Vector3 in
                return colorSRGBfromRGB(Clamp(v, 0, 1)) * 255.0
            }
        }
        sphereMap.update( {(v: Vector3) -> (UInt8, UInt8, UInt8) in
            let o = f(sh.reconstruct(v))
            return (UInt8(o.x), UInt8(o.y), UInt8(o.z))
        })
        updateImgIrradiance()
    }
    
    @IBAction func computeIrradiance(sender: AnyObject) {
        if sphericalHarmonics == nil {
            updateSphericalHarmonics()
        }
        let sh = sphericalHarmonics!
        sphereMap.update( {(v: Vector3) -> (UInt8, UInt8, UInt8) in
            let o = Clamp(sh.GetIrradianceApproximation(v) * (1/PI), 0, 1) * 255.0
            return (UInt8(o.x), UInt8(o.y), UInt8(o.z))
        })
        updateImgIrradiance()
    }
    
    // menu items connected to First Responder
    @IBAction func debugSphereMapRenderCubemap(sender: AnyObject) {
        // just sample the cubemap, for testing the spheremap
        sphereMap.update(cubeMap.directionalSampler)
        updateImgIrradiance()        
    }

    @IBAction func debugSphereMapRenderNormal(sender: AnyObject) {
        sphereMap.update(sphereMap.debugDirection)
        updateImgIrradiance()
    }

    @IBAction func importSideCrossCubemap(sender: AnyObject) {
        let fileDialog : NSOpenPanel = NSOpenPanel()
        fileDialog.allowsMultipleSelection = false
        fileDialog.canChooseDirectories = false
        fileDialog.allowedFileTypes = ["png", "jpg", "tiff"]
        fileDialog.runModal()
        var chosenFile = fileDialog.URL // holds path to selected file, if there is one
        if (chosenFile != nil) {
            let img : NSImage? = NSImage(byReferencingURL: chosenFile!)
            if (img != nil) {
                cubeMap.setSideCrossCubemap(img!)
                updateImgCubemap()
            }
        }
    }

    @IBAction func inferCubemap(sender: AnyObject) {
        let imgNegX = imgViewNegativeX.image
        let imgPosX = imgViewPositiveX.image
        let imgNegZ = imgViewNegativeZ.image
        let imgPosZ = imgViewPositiveZ.image
        let imgNegY = imgViewNegativeY.image
        let imgPosY = imgViewPositiveY.image

        // if all are set, just copy them as sides of the cubemap
        if imgNegX != nil && imgPosX != nil && imgNegZ != nil && imgPosZ != nil && imgNegY != nil && imgPosY != nil {
            cubeMap.setFace(CubeMap.Face.NegativeX, image: imgNegX!)
            cubeMap.setFace(CubeMap.Face.PositiveZ, image: imgPosZ!)
            cubeMap.setFace(CubeMap.Face.PositiveX, image: imgPosX!)
            cubeMap.setFace(CubeMap.Face.NegativeZ, image: imgNegZ!)
            cubeMap.setFace(CubeMap.Face.PositiveY, image: imgPosY!)
            cubeMap.setFace(CubeMap.Face.NegativeY, image: imgNegY!)
            updateImgCubemap()
        }
        // create a cubemap from stretching 2 of the pictures
        else if imgNegX != nil && imgPosX != nil && imgNegY != nil && imgPosY != nil {
            cubeMap.setPanorama(CubeMap.Side.Left, image: imgNegX!)
            cubeMap.setPanorama(CubeMap.Side.Right, image: imgPosX!)
            cubeMap.setFace(CubeMap.Face.PositiveY, image: imgPosY!)
            cubeMap.setFace(CubeMap.Face.NegativeY, image: imgNegY!)
            updateImgCubemap()
        }
        // create a cubemap from just 1 image, assuming it's a spherical projection
        else if imgNegX != nil {
            cubeMap.setSphericalProjectionMap(imgNegX!)
            updateImgCubemap()
        }
    }
    
    @IBAction func saveSphereMap(sender: AnyObject) {
        // Create the File Save Dialog class.
        let fileDialog : NSSavePanel = NSSavePanel()
        fileDialog.allowedFileTypes = ["png"]
        // Display the dialog.  If the OK button was pressed, save
        if fileDialog.runModal() == NSOKButton {
            var chosenFile = fileDialog.URL!
            CGImageWriteToFile(imgIrradiance, chosenFile);
        }
    }
    
    @IBAction func validateNumSamples(sender: AnyObject) {
        let numSamplesOld = sphericalHarmonics == nil ? 0 : sphericalHarmonics!.numSamples
        let defaultValue = 10000
        let number = NSNumberFormatter().numberFromString(textFieldNumSamples.stringValue)
        let numSamples = number != nil ? Clamp(number!.integerValue, 100, 30000) : defaultValue
        textFieldNumSamples.stringValue = "\(numSamples)"
        if numSamplesOld != UInt(numSamples) {
            // SH no longer valid
            sphericalHarmonics = nil
        }
    }
    
    @IBAction func validateNumBands(sender: AnyObject) {
        let numBandsOld = sphericalHarmonics == nil ? 0 : sphericalHarmonics!.numBands
        let defaultValue = 3
        let number = NSNumberFormatter().numberFromString(textFieldNumBands.stringValue)
        let numBands = number != nil ? Clamp(number!.integerValue, 1, 20) : defaultValue
        textFieldNumBands.stringValue = "\(numBands)"
        if numBandsOld != UInt(numBands) {
            // SH no longer valid
            sphericalHarmonics = nil
        }
    }
    
    @IBAction func validateSphereMapResolution(sender: AnyObject) {
        let power = sliderMapResolution.integerValue
        let numPixels = UInt(2 << power)
        sphereMap = SphereMap(w: numPixels, h: numPixels, negYr: sliderPosYPercentage.floatValue)
        updateImgIrradiance()
        // SH no longer valid
        sphericalHarmonics = nil
    }
    
    @IBAction func validatePosYPercentage(sender: AnyObject) {
        sphereMap.negYr = sliderPosYPercentage.floatValue
        debugSphereMapRenderNormal(sender)
    }
    
    @IBAction func validateRGBConversion(sender: AnyObject) {
        // SH no longer valid
        sphericalHarmonics = nil        
    }
    
    // =============================================================
    // NSTableViewDataSource implementation
    // =============================================================
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return sphericalHarmonics == nil ? 0 : Int(sphericalHarmonics!.numCoeffs)
    }
    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject!
    {
        if tableColumn.identifier == "index" {
            return row
        }
        if sphericalHarmonics != nil {
            switch tableColumn.identifier {
            case "red":
                return sphericalHarmonics!.coeffs[row].x
            case "green":
                return sphericalHarmonics!.coeffs[row].y
            case "blue":
                return sphericalHarmonics!.coeffs[row].z
            default:
                break
            }
        }
        return ""
    }
}

