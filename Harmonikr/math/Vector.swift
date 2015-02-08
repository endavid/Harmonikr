//
//  Vector.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/7/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

// -----------------------------------------------------------
class Vector3 {
    var x               : Float = 0
    var y               : Float = 0
    var z               : Float = 0
    
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
    
    
    func Normalize() -> Vector3 {
        // save some computation is is already normalized
        let r2 = LengthSqr(self)
        if (fabsf(r2-1.0)>NORM_SQR_ERROR_TOLERANCE) {
            return ( (1/sqrtf(r2)) * self );
        }
        return self
    }
    
}; // Vector3

// -----------------------------------------------------------
// operators
// -----------------------------------------------------------

func + (left: Vector3, right: Vector3) -> Vector3 {
    return Vector3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}
func += (inout left: Vector3, right: Vector3) {
    left = left + right
}
func - (left: Vector3, right: Vector3) -> Vector3 {
    return Vector3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}
func -= (inout left: Vector3, right: Vector3) {
    left = left - right
}
func * (v: Vector3, f: Float) -> Vector3 {
    return Vector3(x: v.x * f, y: v.y * f, z: v.z * f)
}
func * (f: Float, v: Vector3) -> Vector3 {
    return v * f
}
func *= (inout v: Vector3, f: Float) {
    v = v * f
}

// -----------------------------------------------------
/// dot product
func Dot(v0: Vector3, v1: Vector3) -> Float {
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z
}
/// square-length of a vector
func LengthSqr(v: Vector3) -> Float {
    return Dot(v, v)
}
/// length of a vector
func Length(v: Vector3) -> Float {
    return sqrtf( LengthSqr(v) )
}
