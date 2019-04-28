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
func CGImageWriteToFile(_ image: CGImage, filename: URL) {
    let url = filename as CFURL
    guard let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil) else {
        NSLog("Failed to create destination: \(url)")
        return
    }
    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) {
        NSLog("Failed to write image to \(filename)")
    }
}

class Document: NSDocument, NSTableViewDataSource, NSTableViewDelegate {
    
    var imgIrradiance : CGImage!
    var imgCubemap: CGImage!
    var sphereMap : SphereMap!
    var cubeMap: CubeMap!
    var sphericalHarmonics: SphericalHarmonics?
    var settings: Dictionary<String, String>!
    var imagePaths = [
        "negX": "",
        "posX": "",
        "negY": "",
        "posY": "",
        "negZ": "",
        "posZ": ""
    ]
    
    @IBOutlet weak var imgViewIrradiance: NSImageView!
    @IBOutlet weak var imgViewCubemap: NSImageView!
    // cubemap outlets
    @IBOutlet weak var imgViewNegativeX: CustomImageView!
    @IBOutlet weak var imgViewPositiveX: CustomImageView!
    @IBOutlet weak var imgViewPositiveZ: CustomImageView!
    @IBOutlet weak var imgViewNegativeZ: CustomImageView!
    @IBOutlet weak var imgViewPositiveY: CustomImageView!
    @IBOutlet weak var imgViewNegativeY: CustomImageView!
    @IBOutlet weak var textFieldNumBands: NSTextField!
    @IBOutlet weak var textFieldNumSamples: NSTextField!
    @IBOutlet weak var textFieldLinearScale: NSTextField!
    @IBOutlet weak var tableViewCoeffs: NSTableView!
    @IBOutlet weak var sliderPosYPercentage: NSSlider!
    @IBOutlet weak var sliderMapResolution: NSSlider!
    @IBOutlet weak var buttonRGBConversion: NSButton!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
        cubeMap = CubeMap()
        // directly a dictionary, easier to serialize
        settings = [
            "negYr": "0.6",
            "mapResolution": "6",
            "convertRGB": "true",
            "linearScale": "1.0"
        ]
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    
    // "Swift Development with Cocoa"
    override func data(ofType typeName: String) throws -> Data {
        serializeImagePaths()
        serializeSettings()
        let dic: [String: Any] = ["SH": sphericalHarmonics != nil ? sphericalHarmonics!.toDictionary() : [],
            "settings": settings!,
            "images": imagePaths
        ]
        let serializedData: Data?
        do {
            serializedData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        } catch let error as NSError {
            serializedData = nil
            throw error
        }
        if let value = serializedData {
            return value
        }
        throw NSError(domain: "Migrator", code: 0, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        do {
            let data = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? NSDictionary
            guard let json = data else {
                throw NSError(domain: "Migrator", code: 0, userInfo: nil)
            }
            if let shDic = json["SH"] as? NSDictionary {
                sphericalHarmonics = SphericalHarmonics(dictionary: shDic)
            }
            if let settings = json["settings"] as? Dictionary<String,String> {
                self.settings = settings
            }
            if let images = json["images"] as? Dictionary<String, String> {
                self.imagePaths = images
            }

        } catch let error {
            throw error
        }
    }
    
    /// Initialization code that needs the instantiated IBOutlets (before this function is called, they are still nil!)
    override func awakeFromNib() {
        let power = sliderMapResolution.integerValue
        let numPixels = UInt(2 << power)
        updateSettingsView()
        sphereMap = SphereMap(w: numPixels, h: numPixels, negYr: sliderPosYPercentage.floatValue)
        updateImgIrradiance()
        updateImages()
        inferCubemap(self)
        if sphericalHarmonics == nil {
            updateImgCubemap()
        }
    }
    
    func updateImages() {
        if imagePaths["negX"] != nil && !imagePaths["negX"]!.isEmpty {
            imgViewNegativeX.image = NSImage(byReferencingFile: imagePaths["negX"]!)
        }
        if imagePaths["posX"] != nil && !imagePaths["posX"]!.isEmpty {
            imgViewPositiveX.image = NSImage(byReferencingFile: imagePaths["posX"]!)
        }
        if imagePaths["negY"] != nil && !imagePaths["negY"]!.isEmpty {
            imgViewNegativeY.image = NSImage(byReferencingFile: imagePaths["negY"]!)
        }
        if imagePaths["posY"] != nil && !imagePaths["posY"]!.isEmpty {
            imgViewPositiveY.image = NSImage(byReferencingFile: imagePaths["posY"]!)
        }
        if imagePaths["negZ"] != nil && !imagePaths["negZ"]!.isEmpty {
            imgViewNegativeZ.image = NSImage(byReferencingFile: imagePaths["negZ"]!)
        }
        if imagePaths["posZ"] != nil && !imagePaths["posZ"]!.isEmpty {
            imgViewPositiveZ.image = NSImage(byReferencingFile: imagePaths["posZ"]!)
        }
    }
    
    /// Updates the View from the data in the Model
    func updateSettingsView() {
        if settings["linearScale"] == nil {
           settings["linearScale"] = "1.0"
        }
        if sphericalHarmonics != nil {
            textFieldNumBands.stringValue = "\(sphericalHarmonics!.numBands)"
            textFieldNumSamples.stringValue = "\(sphericalHarmonics!.numSamples)"
        }
        sliderPosYPercentage.floatValue = (settings["negYr"]! as NSString).floatValue
        sliderMapResolution.integerValue = Int(settings["mapResolution"]!)!
        buttonRGBConversion.state = settings["convertRGB"] == "true" ? .on : .off
        textFieldLinearScale.floatValue = (settings["linearScale"]! as NSString).floatValue
    }
    
    func serializeImagePaths() {
        imagePaths = [
            "negX": imgViewNegativeX.localPath,
            "posX": imgViewPositiveX.localPath,
            "negY": imgViewNegativeY.localPath,
            "posY": imgViewPositiveY.localPath,
            "negZ": imgViewNegativeZ.localPath,
            "posZ": imgViewPositiveZ.localPath
        ]
    }
    
    func serializeSettings() {
        settings = [
            "negYr": "\(sliderPosYPercentage.floatValue)",
            "mapResolution": "\(sliderMapResolution.integerValue)",
            "convertRGB": buttonRGBConversion.state == .on ? "true" : "false",
            "linearScale": "\(textFieldLinearScale.floatValue)"
        ]
    }
    
    // ref: https://gist.github.com/irskep/e560be65163efcb04115
    func updateImgIrradiance() {
        let rgb = CGColorSpaceCreateDeviceRGB()
        let bufferLength = sphereMap.bufferLength
        guard let provider = CGDataProvider(dataInfo: nil, data: sphereMap.imgBuffer, size: bufferLength, releaseData: {_,_,_ in }) else {
            NSLog("Error creating provider")
            return
        }
        let bitmapInfo = CGBitmapInfo.byteOrderMask
        // with alpha
        // bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.Last.rawValue)
        imgIrradiance = CGImage(width: sphereMap.width, height: sphereMap.height, bitsPerComponent: 8, bitsPerPixel: 8 * sphereMap.bands, bytesPerRow: sphereMap.width * sphereMap.bands, space: rgb, bitmapInfo: bitmapInfo, provider: provider, decode: nil /*decode*/, shouldInterpolate: false /*shouldInterpolate*/, intent: .defaultIntent)
        imgViewIrradiance.image = NSImage(cgImage: imgIrradiance, size: NSZeroSize)
    }
    
    func updateImgCubemap() {
        let rgb = CGColorSpaceCreateDeviceRGB()
        let bufferLength = cubeMap.bufferLength
        guard let provider = CGDataProvider(dataInfo: nil, data: cubeMap.imgBuffer, size: bufferLength, releaseData: {_,_,_ in }) else {
            NSLog("Error creating provider")
            return
        }
        let bitmapInfo = CGBitmapInfo.byteOrderMask
        imgCubemap = CGImage(width: cubeMap.width * cubeMap.numFaces, height: cubeMap.height, bitsPerComponent: 8, bitsPerPixel: 8 * cubeMap.numBands, bytesPerRow: cubeMap.width * cubeMap.numBands * cubeMap.numFaces, space: rgb, bitmapInfo: bitmapInfo, provider: provider, decode: nil /*decode*/, shouldInterpolate: false /*shouldInterpolate*/, intent: .defaultIntent)
        imgViewCubemap.image = NSImage(cgImage: imgCubemap, size: NSZeroSize)
        // SH no longer valid
        sphericalHarmonics = nil
    }
    
    func updateSphericalHarmonics() {
        sphericalHarmonics = SphericalHarmonics(numBands: UInt(textFieldNumBands.integerValue), numSamples: UInt(textFieldNumSamples.integerValue))
        if buttonRGBConversion.state == .on {
            // function to sample & convert to linear RGB
            let f = { (θ: Float, φ: Float) -> Vector3 in
                return colorRGBfromSRGB(self.cubeMap.polarSampler(θ: θ, φ: φ))
            }
            // compute spherical harmonics
            let _ = sphericalHarmonics?.projectPolarFn(f)
        } else {
            let _ = sphericalHarmonics?.projectPolarFn(cubeMap.polarSampler)
        }
        tableViewCoeffs.reloadData()
    }

    @IBAction func computeHarmonics(_ sender: AnyObject) {
        if sphericalHarmonics == nil {
            updateSphericalHarmonics()
        }
        let scale = textFieldLinearScale.floatValue
        let sh = sphericalHarmonics!
        var f = { (v: Vector3) -> Vector3 in
                return Clamp(v, low: 0, high: 1) * 255.0
            }
        if buttonRGBConversion.state == .on {
            // function to sample & convert back to gamma RGB
            f = { (v: Vector3) -> Vector3 in
                return colorSRGBfromRGB(Clamp(v, low: 0, high: 1)) * 255.0
            }
        }
        sphereMap.update( {(v: Vector3) -> (UInt8, UInt8, UInt8) in
            let o = f(scale * sh.reconstruct(direction: v))
            return (UInt8(o.x), UInt8(o.y), UInt8(o.z))
        })
        updateImgIrradiance()
    }
    
    @IBAction func computeIrradiance(_ sender: AnyObject) {
        if sphericalHarmonics == nil {
            updateSphericalHarmonics()
        }
        let scale = textFieldLinearScale.floatValue
        let sh = sphericalHarmonics!
        sphereMap.update( {(v: Vector3) -> (UInt8, UInt8, UInt8) in
            let o = Clamp(scale * sh.GetIrradianceApproximation(normal: v) * (1/PI), low: 0, high: 1) * 255.0
            return (UInt8(o.x), UInt8(o.y), UInt8(o.z))
        })
        updateImgIrradiance()
    }
    
    // menu items connected to First Responder
    @IBAction func debugSphereMapRenderCubemap(_ sender: AnyObject) {
        // just sample the cubemap, for testing the spheremap
        sphereMap.update(cubeMap.directionalSampler)
        updateImgIrradiance()        
    }

    @IBAction func debugSphereMapRenderNormal(_ sender: AnyObject) {
        sphereMap.update(sphereMap.debugDirection)
        updateImgIrradiance()
    }

    @IBAction func importSideCrossCubemap(_ sender: AnyObject) {
        let fileDialog : NSOpenPanel = NSOpenPanel()
        fileDialog.allowsMultipleSelection = false
        fileDialog.canChooseDirectories = false
        fileDialog.allowedFileTypes = ["png", "jpg", "tiff"]
        fileDialog.runModal()
        if let chosenFile = fileDialog.url { // holds path to selected file, if there is one
            let img = NSImage(byReferencing: chosenFile)
            cubeMap.setSideCrossCubemap(img)
            updateImgCubemap()
        }
    }

    @IBAction func inferCubemap(_ sender: AnyObject) {
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
            if imgNegY != nil { // overwrite ground
                cubeMap.setFace(CubeMap.Face.NegativeY, image: imgNegY!)                
            }
            updateImgCubemap()
        }
    }
    
    @IBAction func saveSphereMap(_ sender: AnyObject) {
        // Create the File Save Dialog class.
        let fileDialog : NSSavePanel = NSSavePanel()
        fileDialog.allowedFileTypes = ["png"]
        // Display the dialog.  If the OK button was pressed, save
        if fileDialog.runModal() == .OK {
            if let chosenFile = fileDialog.url {
                CGImageWriteToFile(imgIrradiance, filename: chosenFile)
            }
        }
    }
    
    @IBAction func validateNumSamples(_ sender: AnyObject) {
        let numSamplesOld = sphericalHarmonics == nil ? 0 : sphericalHarmonics!.numSamples
        let defaultValue = 10000
        let number = NumberFormatter().number(from: textFieldNumSamples.stringValue)
        let value = number?.intValue ?? defaultValue
        var numSamples = Clamp(value, low: 100, high: 30000)
        let numSamplesSqrt = UInt(sqrtf(Float(numSamples)))
        numSamples = Int(numSamplesSqrt * numSamplesSqrt)
        textFieldNumSamples.stringValue = "\(numSamples)"
        if numSamplesOld != UInt(numSamples) {
            // SH no longer valid
            sphericalHarmonics = nil
        }
    }
    
    @IBAction func validateNumBands(_ sender: AnyObject) {
        let numBandsOld = sphericalHarmonics == nil ? 0 : sphericalHarmonics!.numBands
        let defaultValue = 3
        let number = NumberFormatter().number(from: textFieldNumBands.stringValue)
        let value = number?.intValue ?? defaultValue
        let numBands = Clamp(value, low: 1, high: 20)
        textFieldNumBands.stringValue = "\(numBands)"
        if numBandsOld != UInt(numBands) {
            // SH no longer valid
            sphericalHarmonics = nil
        }
    }
    
    @IBAction func validateSphereMapResolution(_ sender: AnyObject) {
        let power = sliderMapResolution.integerValue
        let numPixels = UInt(2 << power)
        sphereMap = SphereMap(w: numPixels, h: numPixels, negYr: sliderPosYPercentage.floatValue)
        updateImgIrradiance()
        // SH no longer valid
        sphericalHarmonics = nil
    }
    
    @IBAction func validatePosYPercentage(_ sender: AnyObject) {
        sphereMap.negYr = sliderPosYPercentage.floatValue
        debugSphereMapRenderNormal(sender)
    }
    
    @IBAction func validateRGBConversion(_ sender: AnyObject) {
        // SH no longer valid
        sphericalHarmonics = nil        
    }
    
    @IBAction func validateLinearScale(_ sender: AnyObject) {
        
    }
    
    // =============================================================
    // NSTableViewDataSource implementation
    // =============================================================
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return sphericalHarmonics == nil ? 0 : Int(sphericalHarmonics!.numCoeffs)
    }
    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?,
                   row: Int) -> Any? {
        guard let col = tableColumn else {
            return ""
        }
        let id = col.identifier
        if id.rawValue == "index" {
            return row
        }
        guard let sh = sphericalHarmonics else {
            return ""
        }
        switch id.rawValue {
        case "red":
            return sh.coeffs[row].x
        case "green":
            return sh.coeffs[row].y
        case "blue":
            return sh.coeffs[row].z
        default:
            break
        }
        return ""
    }
}

