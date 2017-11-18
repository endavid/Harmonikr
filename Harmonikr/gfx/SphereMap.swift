//
//  SphereMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/5/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

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

class SphereMap {
    let width       : Int
    let height      : Int
    let bands       : Int = 3     ///< R,G,B
    var negYr       : Float  ///< radius at which to start encoding the negative Y hemisphere
    var imgBuffer   : Array<UInt8>!
        // ! implicitly unwrapped optional, because it will stop being nil after init
    
    var bufferLength: Int {
        get {
            return width * height * bands
        }
    }
    
    init(w: UInt = 64, h: UInt = 64, negYr: Float = 0.5) {
        width = Int(w)
        height = Int(h)
        self.negYr = negYr
        imgBuffer = Array<UInt8>(repeating: 0, count: bufferLength)
        update(debugDirection) // init with UV debug values
    }
        
    /**
    * @brief Creates a map of sphere coordinates on 2D
    * Y axis is defined with respect to the center of the image, being 1 at the center, 0 at radius = 0.7, and -1 if radius >= 1.
    * TODO: convert linear color to sRGB
    */
    func update(_ colorFn: (Vector3) -> (UInt8, UInt8, UInt8) ) {
        let hInv = 1.0/Float(height)
        let wInv = 1.0/Float(width)
        for j in 0..<height {
            // the positive V in OpenGL is on top
            let v = 1 - 2.0 * (Float(j)+0.5) * hInv
            for i in 0..<width {
                let u = 2.0 * (Float(i)+0.5) * wInv - 1.0
                let n = normalEncodingLinear(u: u, v: v, thresholdRadius: negYr)
                let color = colorFn(n)
                imgBuffer[Int(i*bands+bands*width*j)] = color.0
                imgBuffer[Int(i*bands+bands*width*j+1)] = color.1
                imgBuffer[Int(i*bands+bands*width*j+2)] = color.2
            } // i
        } // j
    } // update()
    
    func debugDirection(v: Vector3) -> (UInt8, UInt8, UInt8) {
        let o = 127.5 * v + Vector3(x: 127.5, y: 127.5, z: 127.5)
        //let o = Clamp(1.0 * v, 0, 1) * 255.0
        //let o = Clamp(Vector3(x: v.x, y: 0, z: -v.x), 0, 1) * 255.0
        //let o = Clamp(Vector3(x: v.x, y: 0, z: -v.x), 0, 1) * 255.0
        return (UInt8(o.x), UInt8(o.y), UInt8(o.z))
        //return (UInt8(o.x), 0, UInt8(o.z))
        //return (0, UInt8(o.y), 0)
    }
    
}
