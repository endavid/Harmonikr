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
        update() // init with UV debug values
    }
    
    func getBufferLength() -> (UInt) {
        return width * height * bands
    }
    
    /**
    * @brief Creates a map of sphere coordinates on 2D
    * Y axis is defined with respect to the center of the image, being 1 at the center, 0 at radius = 0.7, and -1 if radius >= 1.
    * TODO: convert linear color to sRGB
    */
    func update() {
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
    
                /*
                if ( sh!= NULL ) {
                    // get irradiance for given direction
                    vd::math::Vector3 n(x,z,y);
                    vd::math::Vector3 irradiance = sh->GetIrradianceApproximation(n);
                    vd::math::Vector4 c(1);
                    c(0) = vd::math::Clamp(irradiance.GetX() * vd::math::PI_INV, 0.f, 1.f);
                    c(1) = vd::math::Clamp(irradiance.GetY() * vd::math::PI_INV, 0.f, 1.f);
                    c(2) = vd::math::Clamp(irradiance.GetZ() * vd::math::PI_INV, 0.f, 1.f);
                    c = vd::gfx::Color(vd::gfx::Color::COLORSPACE_RGB, c).ChangeColorSpace(vd::gfx::Color::COLORSPACE_SRGB).ToVector4();
                    x = 255.f * c.GetX();
                    y = 255.f * c.GetY();
                    z = 255.f * c.GetZ();
                }
                else
                */
                //{
                    // for debugging the UVs
                    x = 127.5 * x + 127.5
                    y = 127.5 * y + 127.5
                    z = 127.5 * z + 127.5
                //}
                imgBuffer[Int(i*bands+bands*width*j)] = UInt8(x)
                imgBuffer[Int(i*bands+bands*width*j+1)] = UInt8(y)
                imgBuffer[Int(i*bands+bands*width*j+2)] = UInt8(z)
            } // i
        } // j
    } // update()
}