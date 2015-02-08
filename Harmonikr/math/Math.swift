//
//  Math.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/7/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

let PI      : Float = 3.1415926535897932384626433832795
let PI_2    = 0.5 * PI
let PI2     = 2.0 * PI
let PI_INV  = 1.0 / PI
let NORM_SQR_ERROR_TOLERANCE : Float = 0.001

/// Converts angle in degrees to radians
func DegToRad(angle: Float) -> Float {
    return angle * (PI/180.0)
}
/// Gets the sign of a number
func Sign(n: Float) -> Float {
    return (n>=0) ?1:-1
}
/// Max
func Max(a: Float, b: Float) -> Float {
    return (a>=b) ?a:b
}
/// Min
func Min(a: Float, b: Float) -> Float {
    return (a<=b) ?a:b
}
/// Clamp
func Clamp(value: Float, lowest: Float, highest: Float) -> Float {
    return (value<lowest) ?lowest:(value>highest) ?highest:value
}
