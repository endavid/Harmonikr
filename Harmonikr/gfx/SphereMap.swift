//
//  SphereMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/5/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

class SphereMap {
    let width       : UInt = 32
    let height      : UInt = 32
    let bands       : UInt = 3     ///< R,G,B
    var imgBuffer   : Array<UInt8>!
        // ! implicitly unwrapped optional, because it will stop being nil after init

    init() {
        let bufferLength : Int = (Int)(getBufferLength())
        imgBuffer = Array<UInt8>(count: bufferLength, repeatedValue: 0)
        update(nil) // init with UV debug values
    }
    
    func getBufferLength() -> (UInt) {
        return width * height * bands
    }
    
    /**
    * @brief Creates a map of sphere coordinates on 2D
    * Y axis is defined with respect to the center of the image, being 1 at the center, 0 at radius = 0.7, and -1 if radius >= 1.
    * TODO: convert linear color to sRGB
    */
    func update(harmonics: SphericalHarmonics?) {
        let hInv = 1.0/Float(height)
        let wInv = 1.0/Float(width)
        for j in 0...(height-1) {
            let v = 2.0 * (Float(j)+0.5) * hInv - 1.0
            for i in 0...(width-1) {
                let u = 2.0 * (Float(i)+0.5) * wInv - 1.0
                var x = u
                var z = v
                var radius = sqrtf(x * x + z * z)
                var y = 1.0 - 2.0 * radius
                if (y < -1.0) {
                    y = -1.0
                }
                // normalize x, z (no div by zero, since never in the center for even sizes)
                var rInv = 1.0/radius
                radius = sqrtf(1.0-y*y)
                x = radius * x * rInv
                z = radius * z * rInv;
    
                if let sh = harmonics {
                    // get irradiance for given direction
                    let n = Vector3(x: x, y: z, z: y)
                    let irradiance = sh.GetIrradianceApproximation(n)
                    let c = Clamp(irradiance * PI_INV, 0, 1)
                    // @ todo change colorspace
                    x = 255 * c.x
                    y = 255 * c.y
                    z = 255 * c.z
                } else {
                    // for debugging the UVs
                    x = 127.5 * x + 127.5
                    y = 127.5 * y + 127.5
                    z = 127.5 * z + 127.5
                }
                imgBuffer[Int(i*bands+bands*width*j)] = UInt8(x)
                imgBuffer[Int(i*bands+bands*width*j+1)] = UInt8(y)
                imgBuffer[Int(i*bands+bands*width*j+2)] = UInt8(z)
            } // i
        } // j
    } // update()
}