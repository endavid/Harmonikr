//
//  CubeMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/6/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import AppKit

/// faces of the cubemap
enum CubeMapFace: Int {
    // order them as in Unity https://docs.unity3d.com/Manual/class-Cubemap.html
    // and as in Metal https://developer.apple.com/documentation/metal/mtltexturetype
    case PositiveX = 0, NegativeX, PositiveY, NegativeY, PositiveZ, NegativeZ
}

let CubeMapFaces: [CubeMapFace] = [.PositiveX, .NegativeX, .PositiveY, .NegativeY, .PositiveZ, .NegativeZ]

/// 2 faces of a cubemap (Left: -X,Z; Right: X,-Z)
enum CubeMapSide: Int {
    case Left = 0, Right
}

/**
 *  Keeps the cubemap data.
 *  About cubemaps: http://www.nvidia.com/object/cube_map_ogl_tutorial.html
 */
class CubeMap<T: Number> {
    let width       : Int
    let height      : Int
    let numBands    : Int = 3     ///< R,G,B
    let numFaces    : Int = 6
    var imgBuffer   : Array<T>!
    
    var imageWidth: Int { get { return width * numFaces } }
    var imageHeight: Int { get { return height }}
    var bufferLength: Int { get { return imageWidth * imageHeight * numBands } }
                
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let zero: T = 0
        imgBuffer = Array<T>(repeating: zero, count: bufferLength)
    }
    
    convenience init(cubemap: CubeMap<T>) {
        self.init(width: cubemap.width, height: cubemap.height)
        for face in CubeMapFaces {
            for y in 0..<height {
                for x in 0..<width {
                    let c = cubemap.pixelSampler(face: face, x: x, y: y)
                    let k = getArrayIndex(face: face, x: x, y: y)
                    imgBuffer[k] = c.r
                    imgBuffer[k+1] = c.g
                    imgBuffer[k+2] = c.b
                }
            }
        }
    }
    
    private func set(sampler: ImageSampler, index k: Int, u: Float, v: Float) {
        let sample: (r: T, g: T, b: T, a: T) = sampler.uvSampler(u: u, v: v)
        imgBuffer[k] = sample.r
        imgBuffer[k+1] = sample.g
        imgBuffer[k+2] = sample.b
    }
    
    func getArrayIndex(face: CubeMapFace, x: Int, y: Int) -> Int {
        let faceOffset = face.rawValue * width * numBands
        let k = faceOffset + x*numBands+numBands*width*numFaces*y
        return k
    }
    
    // Ref. https://docs.unity3d.com/es/current/Manual/class-Cubemap.html
    func setSideCrossCubemap(_ image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let v = Float(j) / Float(height) / 3
            // copy the 4 xz faces
            // The 1-line cubemaps are in this order: +X, -X, +Y, -Y, +Z, -Z, and so it's the image buffer
            // whereas in the side-cross the middle line is: -X, +Z, +X, -Z
            let targetIndeces = [CubeMapFace.NegativeX.rawValue, CubeMapFace.PositiveZ.rawValue, CubeMapFace.PositiveX.rawValue, CubeMapFace.NegativeZ.rawValue]
            for sourceIndex in 0..<4 {
                let targetIndex = targetIndeces[sourceIndex]
                for i in 0..<width {
                    let u = Float(i) / Float(width) / 4 + Float(sourceIndex) / 4
                    let k = Int(targetIndex * width * numBands + i*numBands+numBands*width*numFaces*j)
                    set(sampler: sampler, index: k, u: u, v: v + 1/3)
                }
            }
            // copy Y+ and Y-
            for i in 0..<width {
                let u = Float(i) / Float(width) / 4
                let k0 = Int(CubeMapFace.PositiveY.rawValue * width * numBands + i*numBands+numBands*width*numFaces*j)
                let k1 = Int(CubeMapFace.NegativeY.rawValue * width * numBands + i*numBands+numBands*width*numFaces*j)
                set(sampler: sampler, index: k0, u: u + 1/4, v: v)
                set(sampler: sampler, index: k1, u: u + 1/4, v: v + 2/3)
            }
        }
    }
    
    /// Initializes a face of the cubemap with the given image
    func setFace(_ face: CubeMapFace, image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let v = Float(j) / Float(height)
            for i in 0..<width {
                let u = Float(i) / Float(width)
                let faceOffset = face.rawValue * width * numBands
                let k = Int(faceOffset + i*numBands+numBands*width*numFaces*j)
                set(sampler: sampler, index: k, u: u, v: v)
            }
        }
    }
    
    func setFace(_ face: CubeMapFace, sampler: (Vector3) -> (r: T, g: T, b: T), rotationY: Float) {
        for j in 0..<height {
            let v = Float(j) / Float(height)
            for i in 0..<width {
                let u = Float(i) / Float(width)
                let faceOffset = face.rawValue * width * numBands
                let k = Int(faceOffset + i*numBands+numBands*width*numFaces*j)
                var dir = Vector3(x: 1, y: 0, z: 0)
                switch face {
                case .NegativeX:
                    dir = Vector3(x: -1, y: 1 - 2 * v, z: -1 + 2 * u)
                case .PositiveX:
                    dir = Vector3(x: 1, y: 1 - 2 * v, z: 1 - 2 * u)
                case .NegativeY:
                    dir = Vector3(x: -1 + 2 * u, y: -1, z: 1 - 2 * v)
                case .PositiveY:
                    dir = Vector3(x: -1 + 2 * u, y: 1, z: -1 + 2 * v)
                case .NegativeZ:
                    dir = Vector3(x: 1 - 2 * u, y: 1 - 2 * v, z: -1)
                case .PositiveZ:
                    dir = Vector3(x: -1 + 2 * u, y: 1 - 2 * v, z: 1)
                }
                let sph = Spherical(v: dir.normalize())
                let sphY = Spherical(r: 1, θ: sph.θ, φ: sph.φ + rotationY)
                let c = sampler(sphY.ToVector3())
                imgBuffer[k] = c.r
                imgBuffer[k+1] = c.g
                imgBuffer[k+2] = c.b
            }
        }
    }
    
    func setCubeMap(_ c: CubeMap, rotationY: Float) {
        for face in CubeMapFaces {
            setFace(face, sampler: c.directionalSampler, rotationY: rotationY)
        }
    }
    
    /// Initializes 2 faces of the cubemap with the give image
    func setPanorama(_ side: CubeMapSide, image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let v = Float(j) / Float(height)
            for i in 0..<2*width {
                let u = Float(i) / Float(2*width)
                let sideOffset = side.rawValue * 2 * width * numBands
                let k = Int(sideOffset + i*numBands+numBands*width*numFaces*j)
                set(sampler: sampler, index: k, u: u, v: v)
            }
        }
    }
    
    /// Pass a spherical projection map to initialize the cubemap
    func setSphericalProjectionMap(_ image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let t = Float(j) / Float(height)
            let tc = 2.0 * t - 1.0
            for i in 0..<width {
                let s = Float(i) / Float(width)
                let sc = 2.0 * s - 1.0
                let posX = Spherical( v: Vector3(x: 1, y: -tc, z: -sc).normalize() )
                let negX = Spherical( v: Vector3(x: -1, y: -tc, z: sc).normalize() )
                let posY = Spherical( v: Vector3(x: sc, y: 1, z: tc).normalize() )
                let negY = Spherical( v: Vector3(x: sc, y: -1, z: -tc).normalize() )
                let posZ = Spherical( v: Vector3(x: sc, y: -tc, z: 1).normalize() )
                let negZ = Spherical( v: Vector3(x: -sc, y: -tc, z: -1).normalize() )
                let texcoords = [
                    (u: posX.φ / PI2, v: posX.θ * PI_INV),
                    (u: negX.φ / PI2, v: negX.θ * PI_INV),
                    (u: posY.φ / PI2, v: posY.θ * PI_INV),
                    (u: negY.φ / PI2, v: negY.θ * PI_INV),
                    (u: posZ.φ / PI2, v: posZ.θ * PI_INV),
                    (u: negZ.φ / PI2, v: negZ.θ * PI_INV)
                ]
                for face in 0...5 {
                    let faceOffset = face * Int(width * numBands)
                    let k = Int(faceOffset) + Int(i*numBands+numBands*width*numFaces*j)
                    set(sampler: sampler, index: k, u: texcoords[face].u, v: texcoords[face].v)
                }
            }
        }
    }
    
    // @todo replace by getPolarSampler; pass option to apply linear RGB conversion
    func polarSampler(θ: Float, φ: Float) -> Vector3 {
        let vec = Spherical(r: 1, θ: θ, φ: φ).ToVector3()
        let c = directionalSampler(vec)
        let color = Vector3(x: c.r.asFloat, y: c.g.asFloat, z: c.b.asFloat) * (1.0/T.norm)
        return color
    }
    
    func directionalSampler(_ vec: Vector3) -> (r: T, g: T, b: T) {
        // Find major axis direction
        var maxAxis = CubeMapFace.PositiveX
        var maxAxisValue = vec.x
        if -vec.x > maxAxisValue {
            maxAxis = CubeMapFace.NegativeX
            maxAxisValue = -vec.x
        }
        if vec.y > maxAxisValue {
            maxAxis = CubeMapFace.PositiveY
            maxAxisValue = vec.y
        }
        if -vec.y > maxAxisValue {
            maxAxis = CubeMapFace.NegativeY
            maxAxisValue = -vec.y
        }
        if vec.z > maxAxisValue {
            maxAxis = CubeMapFace.PositiveZ
            maxAxisValue = vec.z
        }
        if -vec.z > maxAxisValue {
            maxAxis = CubeMapFace.NegativeZ
            maxAxisValue = -vec.z
        }
        var sc : Float = 0
        var tc : Float = 0
        switch maxAxis {
        case .PositiveX:
            sc = -vec.z; tc = -vec.y
            break
        case .NegativeX:
            sc = vec.z; tc = -vec.y
            break
        case .PositiveY:
            sc = vec.x; tc = vec.z
            break
        case .NegativeY:
            sc = vec.x; tc = -vec.z
            break
        case .PositiveZ:
            sc = vec.x; tc = -vec.y
            break
        case .NegativeZ:
            sc = -vec.x; tc = -vec.y
            break
        }
        let s = ( sc/abs(maxAxisValue) + 1 ) / 2
        let t = ( tc/abs(maxAxisValue) + 1 ) / 2
        return uvSampler(face: maxAxis, u: s, v: t)
    }
    
    func uvSampler(face: CubeMapFace, u: Float, v: Float) -> (r: T, g: T, b: T) {
        let i = Int( Float(width) * u )
        let j = Int( Float(height) * v )
        return pixelSampler(face: face, x: i, y: j)
    }
    
    func pixelSampler(face: CubeMapFace, x: Int, y: Int) -> (r: T, g: T, b: T) {
        let xc = Clamp(x, low: 0, high: width - 1)
        let yc = Clamp(y, low: 0, high: height - 1)
        let k = getArrayIndex(face: face, x: xc, y: yc)
        return (imgBuffer[k], imgBuffer[k+1], imgBuffer[k+2])
    }
    
    func createProvider() -> CGDataProvider? {
        let size = bufferLength * MemoryLayout<T>.size
        var provider: CGDataProvider?
        imgBuffer.withUnsafeBytes { data in
            if let ptr = data.baseAddress {
                provider = CGDataProvider(dataInfo: nil, data: ptr, size: size, releaseData: {_,_,_ in })
            }
        }
        return provider
    }
    
}

class GenericCubeMap {
    private var cubemap8: CubeMap<UInt8>?
    private var cubemap16: CubeMap<UInt16>?
    private var cubemap32: CubeMap<Float>?
    private var _bitDepth: BitDepth
    private var _cgImage: CGImage?
    let width: Int
    let height: Int
    let numBands: Int = 3     ///< R,G,B
    let numFaces: Int = 6
    
    var imageWidth: Int {
        get {
            return cubemap8?.imageWidth ?? cubemap16?.imageWidth ?? cubemap32?.imageWidth ?? 0
        }
    }
    var imageHeight: Int {
        get {
            return cubemap8?.imageHeight ?? cubemap16?.imageHeight ?? cubemap32?.imageHeight ?? 0
        }
    }
    var bufferLength: Int { get { return imageWidth * imageHeight * numBands } }
    
    var cgImage: CGImage? {
        get {
            return _cgImage
        }
    }
    
    
    var bitDepth: BitDepth {
        get {
            return _bitDepth
        }
        set {
            if _bitDepth != newValue {
                cubemap8 = nil
                cubemap16 = nil
                cubemap32 = nil
                _bitDepth = newValue
                switch(newValue) {
                case .ldr:
                    cubemap8 = CubeMap(width: width, height: height)
                case .hdr16:
                    cubemap16 = CubeMap(width: width, height: height)
                case .hdr32:
                    cubemap32 = CubeMap(width: width, height: height)
                }
            }
        }
    }
    
    init(width: Int, height: Int, bitDepth: BitDepth) {
        self.width = width
        self.height = height
        self._bitDepth = bitDepth
        switch(bitDepth) {
        case .ldr:
            cubemap8 = CubeMap(width: width, height: height)
        case .hdr16:
            cubemap16 = CubeMap(width: width, height: height)
        case .hdr32:
            cubemap32 = CubeMap(width: width, height: height)
        }
    }
    
    init(cubemap: GenericCubeMap, isSideCross: Bool) {
        self.width = cubemap.width
        self.height = cubemap.height
        self._bitDepth = cubemap.bitDepth
        if isSideCross {
            if let c8 = cubemap.cubemap8 {
                cubemap8 = SideCrossCubeMap(cubemap: c8)
            }
            if let c16 = cubemap.cubemap16 {
                cubemap16 = SideCrossCubeMap(cubemap: c16)
            }
            if let c32 = cubemap.cubemap32 {
                cubemap32 = SideCrossCubeMap(cubemap: c32)
            }
        } else {
            if let c8 = cubemap.cubemap8 {
                cubemap8 = CubeMap(cubemap: c8)
            }
            if let c16 = cubemap.cubemap16 {
                cubemap16 = CubeMap(cubemap: c16)
            }
            if let c32 = cubemap.cubemap32 {
                cubemap32 = CubeMap(cubemap: c32)
            }
        }
    }
    
    func createImage() -> NSImage? {
        let prov = cubemap8?.createProvider()
            ?? cubemap16?.createProvider()
            ?? cubemap32?.createProvider()
            ?? nil
        guard let provider = prov else {
            NSLog("Error creating image provider for CubeMap")
            return nil
        }
        let csname = bitDepth == .ldr ? CGColorSpace.sRGB : CGColorSpace.linearSRGB
        guard let colorspace = CGColorSpace(name: csname) else {
            NSLog("Failed to create color space: \(csname)")
            return nil
        }
        var bitmapInfoRaw = CGBitmapInfo.byteOrderMask.rawValue
        if let _ = cubemap32 {
            bitmapInfoRaw |= CGBitmapInfo.floatComponents.rawValue
        }
        let bitmapInfo = CGBitmapInfo(rawValue: bitmapInfoRaw)
        let bits = bitDepth.toBits()
        let bytesPerComponent = bits / 8
        _cgImage = CGImage(width: imageWidth, height: imageHeight, bitsPerComponent: bits, bitsPerPixel: bits * numBands, bytesPerRow: bytesPerComponent * imageWidth * numBands, space: colorspace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: .perceptual)
        guard let cgImage = _cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSZeroSize)
    }
    
    func polarSampler(θ: Float, φ: Float) -> Vector3 {
        if let cubemap = cubemap8 {
            // convert to linear RGB 8-bit images
            return colorRGBfromSRGB(cubemap.polarSampler(θ: θ, φ: φ))
        }
        // assume 16-bit and 32-bit images are in linear RGB already
        if let cubemap = cubemap16 {
            return cubemap.polarSampler(θ: θ, φ: φ)
        }
        if let cubemap = cubemap32 {
            return cubemap.polarSampler(θ: θ, φ: φ)
        }
        return .zero
    }
    
    func setCubeMap(_ c: GenericCubeMap, rotationY: Float) {
        // only one of them will be non-null at a time
        if let c8 = c.cubemap8 {
            cubemap8?.setCubeMap(c8, rotationY: rotationY)
        }
        if let c16 = c.cubemap16 {
            cubemap16?.setCubeMap(c16, rotationY: rotationY)
        }
        if let c32 = c.cubemap32 {
            cubemap32?.setCubeMap(c32, rotationY: rotationY)
        }
    }
    
    func setFace(_ face: CubeMapFace, image: NSImage) {
        // only one of them will be non-null at a time
        cubemap8?.setFace(face, image: image)
        cubemap16?.setFace(face, image: image)
        cubemap32?.setFace(face, image: image)
    }
    
    func setPanorama(_ side: CubeMapSide, image: NSImage) {
        // only one of them will be non-null at a time
        cubemap8?.setPanorama(side, image: image)
        cubemap16?.setPanorama(side, image: image)
        cubemap32?.setPanorama(side, image: image)
    }
    
    func setSideCrossCubemap(_ image: NSImage) {
        // only one of them will be non-null at a time
        cubemap8?.setSideCrossCubemap(image)
        cubemap16?.setSideCrossCubemap(image)
        cubemap32?.setSideCrossCubemap(image)
    }
    
    func setSphericalProjectionMap(_ image: NSImage) {
        // only one of them will be non-null at a time
        cubemap8?.setSphericalProjectionMap(image)
        cubemap16?.setSphericalProjectionMap(image)
        cubemap32?.setSphericalProjectionMap(image)
    }
    
    func toRadianceData() -> Data {
        if let c8 = cubemap8 {
            return RgbeWriter.toRadianceData(width: imageWidth, height: imageHeight, imgData: c8.imgBuffer)
        }
        if let c16 = cubemap16 {
            return RgbeWriter.toRadianceData(width: imageWidth, height: imageHeight, imgData: c16.imgBuffer)
        }
        if let c32 = cubemap32 {
            return RgbeWriter.toRadianceData(width: imageWidth, height: imageHeight, imgData: c32.imgBuffer)
        }
        return Data()
    }
    
}
