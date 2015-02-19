//
//  SphereMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/5/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

func normalEncodingLinear(#u: Float, #v: Float, #thresholdRadius: Float) -> Vector3 {
    var o = Vector3()
    let radius = sqrtf(u * u + v * v)
    // encode both Y+ and Y- hemispheres
    // (no div by zero, since never in the center for even sizes)
    let yNegSide = Clamp((radius/thresholdRadius - 1)/(1-thresholdRadius), 0, 1/thresholdRadius)
    let s = (1 / thresholdRadius - yNegSide)
    o.x = Clamp(u * s, -1, 1)
    o.z = Clamp(v * s, -1, 1)
    o.y = Sign(1-radius/thresholdRadius)*sqrtf(1 - Clamp(o.x * o.x + o.z * o.z, 0, 1))
    return o
}

class SphereMap {
    let width       : UInt = 32
    let height      : UInt = 32
    let bands       : UInt = 3     ///< R,G,B
    var imgBuffer   : Array<UInt8>!
        // ! implicitly unwrapped optional, because it will stop being nil after init

    init() {
        let bufferLength : Int = (Int)(getBufferLength())
        imgBuffer = Array<UInt8>(count: bufferLength, repeatedValue: 0)
        update(debugDirection) // init with UV debug values
    }
    
    func getBufferLength() -> (UInt) {
        return width * height * bands
    }
    
    /**
    * @brief Creates a map of sphere coordinates on 2D
    * Y axis is defined with respect to the center of the image, being 1 at the center, 0 at radius = 0.7, and -1 if radius >= 1.
    * TODO: convert linear color to sRGB
    */
    func update(colorFn: Vector3 -> (UInt8, UInt8, UInt8) ) {
        let hInv = 1.0/Float(height)
        let wInv = 1.0/Float(width)
        // radius at which to start encoding the negative Y hemisphere
        let negYr : Float = 0.7
        for j in 0..<height {
            // the positive V in OpenGL is on top
            let v = 1 - 2.0 * (Float(j)+0.5) * hInv
            for i in 0..<width {
                let u = 2.0 * (Float(i)+0.5) * wInv - 1.0
                let n = normalEncodingLinear(u: u, v: v, thresholdRadius: negYr)
                let color = colorFn(n)

                /*
                if let sh = harmonics {
                    // get irradiance for given direction
                    let n = Vector3(x: x, y: z, z: y)
                    let irradiance = sh.GetIrradianceApproximation(n)
                    let c = Clamp(irradiance * PI_INV, 0, 1)
                    // @ todo change colorspace
                    x = 255 * c.x
                    y = 255 * c.y
                    z = 255 * c.z
                }*/
                imgBuffer[Int(i*bands+bands*width*j)] = color.0
                imgBuffer[Int(i*bands+bands*width*j+1)] = color.1
                imgBuffer[Int(i*bands+bands*width*j+2)] = color.2
            } // i
        } // j
    } // update()
    
    func debugDirection(v: Vector3) -> (UInt8, UInt8, UInt8) {
        let o = 127.5 * v + Vector3(x: 127.5, y: 127.5, z: 127.5)
        //let o = Clamp(v, 0, 1) * 255.0
        return (UInt8(o.x), UInt8(o.y), UInt8(o.z))
        //return (UInt8(o.x), 0, UInt8(o.z))
        //return (0, UInt8(o.y), 0)

    }
    
}