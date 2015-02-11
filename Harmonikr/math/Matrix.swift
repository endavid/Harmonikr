//
//  Matrix.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/10/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

/* 4x4 Matrix, Row major */
struct Matrix4 {
    var values: [Float]
    init() {
        values = Array(count: 4*4, repeatedValue: 0)
    }
    subscript(column: Int, row: Int) -> Float {
        get {
            return values[(row*4)+column]
        }
        set {
            values[(row*4)+column] = newValue
        }
    }
}

// -----------------------------------------------------------
// operators
// -----------------------------------------------------------

func + (left: Matrix4, right: Matrix4) -> Matrix4 {
    var out = Matrix4()
    for i in 0...out.values.count {
        out.values[i] = left.values[i] + right.values[i]
    }
    return out
}

func * (m: Matrix4, v: Vector4) -> Vector4 {
    var out = Vector4()
    out.x = m[0,0]*v.x+m[0,1]*v.y+m[0,2]*v.z+m[0,3]*v.w
    out.y = m[1,0]*v.x+m[1,1]*v.y+m[1,2]*v.z+m[1,3]*v.w
    out.z = m[2,0]*v.x+m[2,1]*v.y+m[2,2]*v.z+m[2,3]*v.w
    out.w = m[3,0]*v.x+m[3,1]*v.y+m[3,2]*v.z+m[3,3]*v.w
    return v
}