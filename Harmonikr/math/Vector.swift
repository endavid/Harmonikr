//
//  Vector.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/7/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

// -----------------------------------------------------------
struct Vector3 : CustomStringConvertible {
    static let zero = Vector3(x: 0, y: 0, z: 0)
    
    var x               : Float = 0
    var y               : Float = 0
    var z               : Float = 0
    var description : String {
        return "(\(x), \(y), \(z))"
    }
    func toString() -> String {
        return description
    }
    
    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    init(value: Float) {
        self.x = value
        self.y = value
        self.z = value
    }
    init() {
    }
    
    subscript(row: Int) -> Float {
        get {
            return row == 0 ? x : row == 1 ? y : z
        }
    }
    
    func normalize() -> Vector3 {
        // save some computation is is already normalized
        let r2 = LengthSqr(self)
        if (fabsf(r2-1.0)>NORM_SQR_ERROR_TOLERANCE) {
            return ( (1/sqrtf(r2)) * self );
        }
        return self
    }
    
    /// Apply a function
    func apply(_ f: (Float) -> Float) -> Vector3 {
        return Vector3(x: f(x), y: f(y), z: f(z))
    }
    
    func toArray() -> [Float] {
        return [x, y, z]
    }

}; // Vector3

// -----------------------------------------------------------
struct Vector4 : CustomStringConvertible {
    var x               : Float = 0
    var y               : Float = 0
    var z               : Float = 0
    var w               : Float = 0
    var description : String {
        return "(\(x), \(y), \(z), \(w))"
    }
    func toString() -> String {
        return description
    }
    
    init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    init(v: Vector3, w: Float) {
        self.x = v.x
        self.y = v.y
        self.z = v.z
        self.w = w
    }
    init(value: Float) {
        self.x = value
        self.y = value
        self.z = value
        self.w = value
    }
    init() {
    }
    
}; // Vector4

// -----------------------------------------------------------
// operators
// -----------------------------------------------------------

func + (left: Vector3, right: Vector3) -> Vector3 {
    return Vector3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}
func += (left: inout Vector3, right: Vector3) {
    left = left + right
}
func - (left: Vector3, right: Vector3) -> Vector3 {
    return Vector3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}
func -= (left: inout Vector3, right: Vector3) {
    left = left - right
}
func * (v: Vector3, f: Float) -> Vector3 {
    return Vector3(x: v.x * f, y: v.y * f, z: v.z * f)
}
func * (f: Float, v: Vector3) -> Vector3 {
    return v * f
}
func *= (v: inout Vector3, f: Float) {
    v = v * f
}

// -----------------------------------------------------
/// dot product
func Dot(_ v0: Vector3, _ v1: Vector3) -> Float {
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z
}
func Dot(_ v0: Vector4, _ v1: Vector4) -> Float {
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z + v0.w * v1.w
}
/// square-length of a vector
func LengthSqr(_ v: Vector3) -> Float {
    return Dot(v, v)
}
/// length of a vector
func Length(_ v: Vector3) -> Float {
    return sqrtf( LengthSqr(v) )
}
/// Clamp
func Clamp(_ v: Vector3, low: Float, high: Float) -> Vector3 {
    var o = v
    o.x = Clamp(o.x, low: low, high: high)
    o.y = Clamp(o.y, low: low, high: high)
    o.z = Clamp(o.z, low: low, high: high)
    return o
}

