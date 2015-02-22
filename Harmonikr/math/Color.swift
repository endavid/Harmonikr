//
//  Color.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/22/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

let SRGB_GAMMA      : Float = 2.4

/// Convert gamma RGB to linear RGB
func colorRGBfromSRGB(srgb: Vector3) -> Vector3 {
    let f = { (c: Float) -> Float in
        if c > 0.04045 {
            return powf((c+0.055)/1.055, SRGB_GAMMA)
        }
        return c * (1 / 12.92)
    }
    return srgb.apply(f)
}

/// Convert linear RGB to gamma RGB
func colorSRGBfromRGB(rgb: Vector3) -> Vector3 {
    let f = { (c: Float) -> Float in
        if c > 0.00304 {
            return 1.055 * powf(c, 1/SRGB_GAMMA) - 0.055
        }
        return c * 12.92
    }
    return rgb.apply(f)
}
