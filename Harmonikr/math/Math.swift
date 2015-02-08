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
let π       : Double = Double(PI)

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
/// Random Int. Preferred to rand() % upperBound
func Rand(upperBound: UInt32) -> UInt32 {
    return arc4random_uniform(upperBound)
}
/// Random Float between 0 and 1
func Randf() -> Float {
    return Float(Rand(10000)) * 0.0001
}
// Factorial of a number with a cache
func Factorial(n: Int) -> Double { // 64-bit ints aren't enough for big factorials
    struct CacheData {
        static let maxCount = 33
        static var isFactorialCached = false
        static var factorialCache : [Double] = [Double](count: maxCount, repeatedValue: 1)
    }
    
    if (n < 2) {
        return 1
    }
    if (!CacheData.isFactorialCached) {
        // init cache
        var r : Double = 1
        for c in 0...(CacheData.maxCount-1) {
            r *= Double(c+2)
            CacheData.factorialCache[c] = r
        }
        CacheData.isFactorialCached = true
    }
    if (n - 2 < CacheData.maxCount) {
        return CacheData.factorialCache[n-2]
    }
    var r = CacheData.factorialCache[CacheData.maxCount-1]
    for i in (CacheData.maxCount+2)...n {
        r *= Double(i)
    }
    return r
}
