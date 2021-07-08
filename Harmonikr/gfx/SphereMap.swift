//
//  SphereMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/5/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import AppKit

/**
 * x = f(r,u) = u/t + sign(u) * clamp(r-t, 0, 1-t) / (t-1) / t
 * f(t,t) = 1, f(t, 0) = 0, f(1,1) = 0
 * To recover the clip (u,v) coordinates from normalized (x,y,z),
 *  u = tx + sign(x) * clamp(r-t, 0, 1-t) / (1-t)
 */
func normalEncodingLinear(u: Float, v: Float, thresholdRadius: Float) -> Vector3 {
    var o = Vector3()
    let r = sqrtf(u * u + v * v)
    let t = thresholdRadius
    // encode both Y+ and Y- hemispheres
    // (no div by zero, since never in the center for even sizes)
    let negSide = Clamp(r - t, low: 0, high: 1 - t) / (t-1) / t
    o.x = Clamp(u / t + Sign(u) * negSide, low: -1, high: 1)
    o.z = Clamp(v / t + Sign(v) * negSide, low: -1, high: 1)
    o.y = Sign(1-r/thresholdRadius)*sqrtf(1 - Clamp(o.x * o.x + o.z * o.z, low: 0, high: 1))
    return o
}

class SphereMap<T: Number> {
    let width       : Int
    let height      : Int
    let bands       : Int = 3     ///< R,G,B
    var negYr       : Float  ///< radius at which to start encoding the negative Y hemisphere
    var imgBuffer   : Array<T>!
        // ! implicitly unwrapped optional, because it will stop being nil after init
    
    var bufferLength: Int {
        get {
            return width * height * bands
        }
    }
    
    init(width w: Int = 64, height h: Int = 64, negYr: Float = 0.5) {
        width = w
        height = h
        self.negYr = negYr
        let zero: T = 0
        imgBuffer = Array<T>(repeating: zero, count: bufferLength)
        update(GenericSphereMap.debugDirection) // init with UV debug values
    }
        
    /**
    * @brief Creates a map of sphere coordinates on 2D
    * Y axis is defined with respect to the center of the image, being 1 at the center, 0 at radius = 0.7, and -1 if radius >= 1.
    * @todo convert linear color to sRGB
    */
    func update(_ colorFn: (Vector3) -> (Vector3) ) {
        let maxValue: Float = T.norm
        let hInv = 1.0/Float(height)
        let wInv = 1.0/Float(width)
        for j in 0..<height {
            // the positive V in OpenGL is on top
            let v = 1 - 2.0 * (Float(j)+0.5) * hInv
            for i in 0..<width {
                let u = 2.0 * (Float(i)+0.5) * wInv - 1.0
                let n = normalEncodingLinear(u: u, v: v, thresholdRadius: negYr)
                let color = colorFn(n)
                imgBuffer[Int(i*bands+bands*width*j)] = T(color.x * maxValue)
                imgBuffer[Int(i*bands+bands*width*j+1)] = T(color.y * maxValue)
                imgBuffer[Int(i*bands+bands*width*j+2)] = T(color.z * maxValue)
            } // i
        } // j
    } // update()
        
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


class GenericSphereMap {
    private var spheremap8: SphereMap<UInt8>?
    private var spheremap16: SphereMap<UInt16>?
    private var spheremap32: SphereMap<Float>?
    private var _bitDepth: BitDepth
    private var _cgImage: CGImage?

    let width: Int
    let height: Int
    let numBands: Int = 3     ///< R,G,B
    var negYr: Float

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
                spheremap8 = nil
                spheremap16 = nil
                spheremap32 = nil
                _bitDepth = newValue
                switch(newValue) {
                case .ldr:
                    spheremap8 = SphereMap(width: width, height: height, negYr: negYr)
                case .hdr16:
                    spheremap16 = SphereMap(width: width, height: height, negYr: negYr)
                case .hdr32:
                    spheremap32 = SphereMap(width: width, height: height, negYr: negYr)
                }
            }
        }
    }
    
    init(width w: Int = 64, height h: Int = 64, bitDepth: BitDepth = .ldr, negYr: Float = 0.5) {
        self.width = w
        self.height = h
        self.negYr = negYr
        self._bitDepth = bitDepth
        self._bitDepth = bitDepth
        switch(bitDepth) {
        case .ldr:
            spheremap8 = SphereMap(width: w, height: h, negYr: negYr)
        case .hdr16:
            spheremap16 = SphereMap(width: w, height: h, negYr: negYr)
        case .hdr32:
            spheremap32 = SphereMap(width: w, height: h, negYr: negYr)
        }
    }
    
    func createImage() -> NSImage? {
        // ref: https://gist.github.com/irskep/e560be65163efcb04115
        let prov = spheremap8?.createProvider()
            ?? spheremap16?.createProvider()
            ?? spheremap32?.createProvider()
            ?? nil
        guard let provider = prov else {
            NSLog("Error creating image provider for SphereMap")
            return nil
        }
        let csname = bitDepth == .ldr ? CGColorSpace.sRGB : CGColorSpace.linearSRGB
        guard let colorspace = CGColorSpace(name: csname) else {
            NSLog("Failed to create color space: \(csname)")
            return nil
        }
        var bitmapInfoRaw = CGBitmapInfo.byteOrderMask.rawValue
        if let _ = spheremap32 {
            bitmapInfoRaw |= CGBitmapInfo.floatComponents.rawValue
        }
        let bitmapInfo = CGBitmapInfo(rawValue: bitmapInfoRaw)
        // with alpha
        // bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.Last.rawValue)
        let bits = bitDepth.toBits()
        let bytesPerComponent = bits / 8
        _cgImage = CGImage(width: width, height: height, bitsPerComponent: bits, bitsPerPixel: bits * numBands, bytesPerRow: bytesPerComponent * width * numBands, space: colorspace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: .perceptual)
        guard let cgImage = _cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSZeroSize)
    }
    
    func update(_ colorFn: (Vector3) -> (Vector3) ) {
        // only one of them will be non-null at a time
        spheremap8?.update(colorFn)
        spheremap16?.update(colorFn)
        spheremap32?.update(colorFn)
    }

    static func debugDirection(v: Vector3) -> (Vector3) {
        return 0.5 * v + Vector3(x: 0.5, y: 0.5, z: 0.5)
        //let o = Clamp(1.0 * v, 0, 1) * 255.0
        //let o = Clamp(Vector3(x: v.x, y: 0, z: -v.x), 0, 1) * 255.0
        //let o = Clamp(Vector3(x: v.x, y: 0, z: -v.x), 0, 1) * 255.0
        //return (UInt8(o.x), 0, UInt8(o.z))
        //return (0, UInt8(o.y), 0)
    }
}
