//
//  Spherical.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/8/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

class Spherical {
    var r       : Float = 1     ///< Radial distance
    var θ       : Float = 0     ///< Inclination (theta) {0,π}
    var φ       : Float = 0     ///< Azimuth (phi) {0,2π}
    
    // Maybe I'll hate myself later for using symbols 😂
    // (they aren't difficult to type with Japanese input, type シータ and ファイ)
    init (r: Float, θ: Float, φ: Float) {
        self.r = r
        self.θ = θ
        self.φ = φ
    }
    
    /// Converts from Cartesian to Spherical coordinates
    init (v: Vector3) {
        r = Length(v)
        θ = acosf(v.y / r)
        // convert -pi..pi to 0..2pi
        φ = atan2f(v.x, v.z)
        φ = φ < 0 ? PI2 + φ : φ
    }
}