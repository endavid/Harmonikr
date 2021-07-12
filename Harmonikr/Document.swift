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
    
    var sphereMap : GenericSphereMap!
    var cubeMap: GenericCubeMap!
    var cubeMapRotated: GenericCubeMap?
    var sphericalHarmonics: SphericalHarmonics?
    var settings: Dictionary<String, String>!
    
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
    @IBOutlet weak var textFieldLinearScale: NSTextField!
    @IBOutlet weak var tableViewCoeffs: NSTableView!
    @IBOutlet weak var sliderPosYPercentage: NSSlider!
    @IBOutlet weak var sliderMapResolution: NSSlider!
    @IBOutlet weak var sliderCubemapSize: NSSlider!
    @IBOutlet weak var precisionCell: NSPopUpButtonCell!
    @IBOutlet weak var sliderRotationY: NSSlider!
    @IBOutlet weak var textFieldRotationY: NSTextField!
    @IBOutlet weak var textFieldPosYPercentage: NSTextField!
    @IBOutlet weak var textFieldMapResolution: NSTextField!
    @IBOutlet weak var textFieldCubemapSize: NSTextField!
    
    var selectedBitDepth: BitDepth {
        get {
            if let item = precisionCell.selectedItem {
                if let bitDepth = BitDepth(rawValue: item.title) {
                    return bitDepth
                }
            }
            return .ldr
        }
    }
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
        cubeMap = GenericCubeMap(width: 64, height: 64, bitDepth: .ldr)
        // directly a dictionary, easier to serialize
        settings = [
            "negYr": "0.6",
            "mapResolution": "6",
            "cubemapSize": "1",
            "linearScale": "1.0",
            "bitDepth": "LDR",
            "rotationY": "0"
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
        serializeSettings()
        let dic: [String: Any] = [
            "SH": sphericalHarmonics?.toDictionary() ?? [],
            "settings": settings!
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
        } catch let error {
            throw error
        }
    }
    
    /// Initialization code that needs the instantiated IBOutlets (before this function is called, they are still nil!)
    override func awakeFromNib() {
        let power = sliderMapResolution.integerValue
        let numPixels = 2 << power
        updateSettingsView()
        sphereMap = GenericSphereMap(width: numPixels, height: numPixels, bitDepth: .ldr, negYr: sliderPosYPercentage.floatValue)
        updateImgIrradiance()
        inferCubemap(self)
        if sphericalHarmonics == nil {
            updateImgCubemap()
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
        let exponent = Int(settings["mapResolution"] ?? "1") ?? 1
        let exponentCubemap = Int(settings["cubemapSize"] ?? "1") ?? 1
        let posY = Round(((settings["negYr"] ?? "0.6") as NSString).doubleValue, digits: 3)
        let linearScale = Round(((settings["linearScale"] ?? "1.0") as NSString).doubleValue, digits: 3)
        sliderPosYPercentage.doubleValue = posY
        sliderMapResolution.integerValue = exponent
        sliderCubemapSize.integerValue = exponentCubemap
        textFieldLinearScale.doubleValue = linearScale
        precisionCell.selectItem(withTitle: settings["bitDepth"] ?? "LDR")
        sliderRotationY.doubleValue = ((settings["rotationY"] ?? "0") as NSString).doubleValue
        textFieldRotationY.doubleValue = sliderRotationY.doubleValue
        textFieldPosYPercentage.doubleValue = sliderPosYPercentage.doubleValue
        let _ = updateSphereMapResolution()
        let _ = updateCubemapSize()
    }
    
    func serializeSettings() {
        settings = [
            "negYr": "\(sliderPosYPercentage.doubleValue)",
            "mapResolution": "\(sliderMapResolution.integerValue)",
            "cubemapSize": "\(sliderCubemapSize.integerValue)",
            "linearScale": "\(textFieldLinearScale.doubleValue)",
            "bitDepth": selectedBitDepth.rawValue,
            "rotationY": "\(sliderRotationY.doubleValue)"
        ]
    }
    
    func updateImgIrradiance() {
        imgViewIrradiance.image = sphereMap.createImage()
    }
    
    func updateImgCubemap() {
        let rotY = textFieldRotationY.floatValue
        if IsClose(rotY, 0) {
            imgViewCubemap.image = cubeMap.createImage()
            cubeMapRotated = nil
        } else {
            let w = cubeMapRotated?.width ?? 0
            let h = cubeMapRotated?.height ?? 0
            let bd = cubeMapRotated?.bitDepth ?? .ldr
            if cubeMap.width != w || cubeMap.height != h || cubeMap.bitDepth != bd {
                cubeMapRotated = GenericCubeMap(width: cubeMap.width, height: cubeMap.height, bitDepth: cubeMap.bitDepth)
            }
            if let cr = cubeMapRotated {
                cr.setCubeMap(cubeMap, rotationY: DegToRad(rotY))
                imgViewCubemap.image = cr.createImage()
            }
        }
        // SH no longer valid
        sphericalHarmonics = nil
    }
    
    func updateSphericalHarmonics() {
        sphericalHarmonics = SphericalHarmonics(numBands: UInt(textFieldNumBands.integerValue), numSamples: UInt(textFieldNumSamples.integerValue))
        let cbr = cubeMapRotated ?? cubeMap!
        let _ = sphericalHarmonics?.projectPolarFn(cbr.polarSampler)
        tableViewCoeffs.reloadData()
    }

    @IBAction func computeHarmonics(_ sender: AnyObject) {
        if sphericalHarmonics == nil {
            updateSphericalHarmonics()
        }
        let scale = textFieldLinearScale.floatValue
        let sh = sphericalHarmonics!
        var f = { (v: Vector3) -> Vector3 in
                return Clamp(v, low: 0, high: 1)
            }
        if sphereMap.bitDepth == .ldr {
            // function to sample & convert back to gamma RGB
            f = { (v: Vector3) -> Vector3 in
                return colorSRGBfromRGB(Clamp(v, low: 0, high: 1))
            }
        }
        sphereMap.update( {(v: Vector3) -> (Vector3) in
            return f(scale * sh.reconstruct(direction: v))
        })
        updateImgIrradiance()
    }
    
    @IBAction func computeIrradiance(_ sender: AnyObject) {
        if sphericalHarmonics == nil {
            updateSphericalHarmonics()
        }
        let scale = textFieldLinearScale.floatValue
        let sh = sphericalHarmonics!
        sphereMap.update( {(v: Vector3) -> (Vector3) in
            return Clamp(scale * sh.GetIrradianceApproximation(normal: v) * (1/PI), low: 0, high: 1)
        })
        updateImgIrradiance()
    }
    
    // menu items connected to First Responder
    @IBAction func debugSphereMapRenderCubemap(_ sender: AnyObject) {
        // just sample the cubemap, for testing the spheremap
        // @todo fix
        //sphereMap.update(cubeMap.directionalSampler)
        updateImgIrradiance()        
    }

    @IBAction func debugSphereMapRenderNormal(_ sender: AnyObject) {
        sphereMap.update(GenericSphereMap.debugDirection)
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
            cubeMap.setFace(.NegativeX, image: imgNegX!)
            cubeMap.setFace(.PositiveZ, image: imgPosZ!)
            cubeMap.setFace(.PositiveX, image: imgPosX!)
            cubeMap.setFace(.NegativeZ, image: imgNegZ!)
            cubeMap.setFace(.PositiveY, image: imgPosY!)
            cubeMap.setFace(.NegativeY, image: imgNegY!)
            updateImgCubemap()
        }
        // create a cubemap from stretching 2 of the pictures
        else if imgNegX != nil && imgPosX != nil && imgNegY != nil && imgPosY != nil {
            cubeMap.setPanorama(.Left, image: imgNegX!)
            cubeMap.setPanorama(.Right, image: imgPosX!)
            cubeMap.setFace(.PositiveY, image: imgPosY!)
            cubeMap.setFace(.NegativeY, image: imgNegY!)
            updateImgCubemap()
        }
        // create a cubemap from just 1 image, assuming it's a spherical projection
        else if imgNegX != nil {
            cubeMap.setSphericalProjectionMap(imgNegX!)
            if imgNegY != nil { // overwrite ground
                cubeMap.setFace(.NegativeY, image: imgNegY!)                
            }
            updateImgCubemap()
        }
    }
    
    @IBAction func saveSphereMap(_ sender: AnyObject) {
        // Create the File Save Dialog class.
        let fileDialog : NSSavePanel = NSSavePanel()
        fileDialog.allowedFileTypes = ["png", "tiff", "hdr"]
        // Display the dialog.  If the OK button was pressed, save
        if fileDialog.runModal() == .OK {
            if let chosenFile = fileDialog.url, let cgImage = sphereMap.cgImage {
                CGImageWriteToFile(cgImage, filename: chosenFile)
            }
        }
    }
    
    @IBAction func saveCubemap(_ sender: AnyObject) {
        // Create the File Save Dialog class.
        let fileDialog : NSSavePanel = NSSavePanel()
        fileDialog.allowedFileTypes = ["png", "tiff", "hdr"]
        // Display the dialog.  If the OK button was pressed, save
        if fileDialog.runModal() == .OK {
            if let chosenFile = fileDialog.url, let cgImage = cubeMapRotated?.cgImage ?? cubeMap.cgImage {
                CGImageWriteToFile(cgImage, filename: chosenFile)
            }
        }
    }
    
    @IBAction func saveSideCrossCubemap(_ sender: Any) {
        let fileDialog : NSSavePanel = NSSavePanel()
        fileDialog.allowedFileTypes = ["png", "tiff", "hdr"]
        // Display the dialog.  If the OK button was pressed, save
        if fileDialog.runModal() == .OK {
            if let chosenFile = fileDialog.url {
                let cubemap = GenericCubeMap(cubemap: cubeMapRotated ?? cubeMap!, isSideCross: true)
                let _ = cubemap.createImage()
                if let cgImage = cubemap.cgImage {
                    CGImageWriteToFile(cgImage, filename: chosenFile)
                }
            }
        }
    }
    
    
    @IBAction func exportCoefficients(_ sender: AnyObject) {
        let fileDialog : NSSavePanel = NSSavePanel()
        fileDialog.allowedFileTypes = ["json"]
        if fileDialog.runModal() == .OK {
            if let chosenFile = fileDialog.url, let stream = OutputStream(url: chosenFile, append: false) {
                stream.open()
                JSONSerialization.writeJSONObject(sphericalHarmonics?.toDictionary() ?? [], to: stream, options: .prettyPrinted, error: nil)
                stream.close()
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
        let numPixels = updateSphereMapResolution()
        sphereMap = GenericSphereMap(width: numPixels, height: numPixels, bitDepth: .ldr, negYr: sliderPosYPercentage.floatValue)
        updateImgIrradiance()
        // SH no longer valid
        sphericalHarmonics = nil
    }
    
    private func updateSphereMapResolution() -> Int {
        let exponent = sliderMapResolution.integerValue
        let numPixels = 2 << exponent
        textFieldMapResolution.stringValue = "\(numPixels)×\(numPixels)"
        return numPixels
    }
    
    @IBAction func validateCubemapSize(_ sender: AnyObject) {
        let numPixels = updateCubemapSize()
        if cubeMap.width != numPixels || cubeMap.height != numPixels {
            cubeMap = GenericCubeMap(width: numPixels, height: numPixels, bitDepth: .ldr)
            updateImgCubemap()
        }
    }
    
    private func updateCubemapSize() -> Int {
        let exponent = sliderCubemapSize.integerValue
        let numPixels = Int(2 << exponent)
        textFieldCubemapSize.stringValue = "\(numPixels*6)×\(numPixels)"
        return numPixels
    }
    
    @IBAction func validatePosYPercentage(_ sender: AnyObject) {
        let p = Round(sliderPosYPercentage.doubleValue, digits: 3)
        sphereMap.negYr = Float(p)
        textFieldPosYPercentage.doubleValue = p
        debugSphereMapRenderNormal(sender)
    }
        
    @IBAction func validateLinearScale(_ sender: AnyObject) {
        
    }
    @IBAction func precisionSelection(_ sender: Any) {
        let bitDepth = selectedBitDepth
        if sphereMap.bitDepth != bitDepth {
            sphereMap.bitDepth = bitDepth
            cubeMap.bitDepth = bitDepth
            sphericalHarmonics = nil // invalidate
        }
    }
    @IBAction func updateRotationY(_ sender: Any) {
        let r = Round(sliderRotationY.doubleValue, digits: 2)
        textFieldRotationY.doubleValue = r
        updateImgCubemap()
    }
    
    // =============================================================
    // NSTableViewDataSource implementation
    // =============================================================
    func numberOfRows(in tableView: NSTableView) -> Int {
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

