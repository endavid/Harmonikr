//
//  Math.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/7/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

protocol Number: Equatable, ExpressibleByIntegerLiteral {
    static var norm: Float { get }
    static var maxFloat: Float { get }
    init(_ source: Float)
    init(_ source: UInt8)
    init(_ source: UInt16)
    init(_ source: UInt32)
    var asFloat: Float { get }
}

extension UInt8: Number {
    static var maxFloat: Float { return Float(UInt8.max) }
    static var norm: Float { return UInt8.maxFloat }
    var asFloat: Float { return Float(self) }
}

extension UInt16: Number {
    static var maxFloat: Float { return Float(UInt16.max) }
    static var norm: Float { return UInt16.maxFloat }
    var asFloat: Float { return Float(self) }
}

extension UInt32: Number {
    // 4294967295 becomes 4294967300 when using floats! it goes out of UInt32 range
    static var maxFloat: Float { return 4.294967e9 }
    static var norm: Float { return UInt32.maxFloat }
    var asFloat: Float { return Float(self) }
}

extension Float: Number {
    static var maxFloat: Float { return Float.greatestFiniteMagnitude }
    static var norm: Float { return 1.0 }
    var asFloat: Float { return self }
}

let PI      : Float = 3.1415926535897932384626433832795
let PI_2    = 0.5 * PI
let PI2     = 2.0 * PI
let PI_INV  = 1.0 / PI
let NORM_SQR_ERROR_TOLERANCE : Float = 0.001
let π       : Double = Double(PI)

/// Converts angle in degrees to radians
func DegToRad(_ angle: Float) -> Float {
    return angle * (PI/180.0)
}
func IsClose(_ a: Float, _ b: Float, epsilon: Float = 0.0001) -> Bool {
    return ( fabsf( a - b ) < epsilon )
}
/// Gets the sign of a number
func Sign(_ n: Float) -> Float {
    return (n>=0) ?1:-1
}
/// Max
func Max(_ a: Float,_ b: Float) -> Float {
    return (a>=b) ?a:b
}
/// Min
func Min(_ a: Float,_ b: Float) -> Float {
    return (a<=b) ?a:b
}
/// Clamp
func Clamp(_ value: Float, low: Float, high: Float) -> Float {
    return (value<low) ?low:(value>high) ?high:value
}
func Clamp(_ value: Int, low: Int, high: Int) -> Int {
    return (value<low) ?low:(value>high) ?high:value
}
/// Random Int. Preferred to rand() % upperBound
func Rand(_ upperBound: UInt32) -> UInt32 {
    return arc4random_uniform(upperBound)
}
/// Random Float between 0 and 1
func Randf() -> Float {
    return Float(Rand(10000)) * 0.0001
}
/// Choose Float digits
func Round(_ a: Double, digits: Int) -> Double {
    let m = pow(10, Double(digits))
    let rounded = Int64(a * m)
    return Double(rounded) / m
}
// Factorial of a number with a cache
func Factorial(_ n: Int) -> Double { // 64-bit ints aren't enough for big factorials
    struct CacheData {
        static let maxCount = 33
        static var isFactorialCached = false
        static var factorialCache : [Double] = [Double](repeating: 1, count: maxCount)
    }
    
    if (n < 2) {
        return 1
    }
    if (!CacheData.isFactorialCached) {
        // init cache
        var r : Double = 1
        for c in 0..<CacheData.maxCount {
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
