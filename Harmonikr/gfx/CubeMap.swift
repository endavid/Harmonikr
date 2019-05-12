//
//  CubeMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/6/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import AppKit

/**
 *  Keeps the cubemap data.
 *  About cubemaps: http://www.nvidia.com/object/cube_map_ogl_tutorial.html
 */
class CubeMap {
    let width       : Int
    let height      : Int
    let numBands    : Int = 3     ///< R,G,B
    let numFaces    : Int = 6
    var imgBuffer   : Array<UInt8>!
    
    var bufferLength: Int {
        get {
            return width * height * numBands * numFaces
        }
    }
    
    /// faces of the cubemap
    enum Face: Int {
        // order them as in Unity https://docs.unity3d.com/Manual/class-Cubemap.html
        // and as in Metal https://developer.apple.com/documentation/metal/mtltexturetype
        case PositiveX = 0, NegativeX, PositiveY, NegativeY, PositiveZ, NegativeZ
    }
    
    /// 2 faces of a cubemap (Left: -X,Z; Right: X,-Z)
    enum Side: Int {
        case Left = 0, Right
    }
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        imgBuffer = Array<UInt8>(repeating: 0, count: bufferLength)
    }
    
    func setSideCrossCubemap(_ image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let v = Float(j) / Float(height) / 3
            // copy the 4 xz faces
            for i in 0..<4*width {
                let u = Float(i) / Float(width) / 4
                let sample = sampler.uvSampler(u: u, v: v + 1/3)
                let k = Int(i*numBands+numBands*width*numFaces*j)
                imgBuffer[k] = sample.r
                imgBuffer[k+1] = sample.g
                imgBuffer[k+2] = sample.b
            }
            // copy Y+ and Y-
            for i in 0..<width {
                let u = Float(i) / Float(width) / 4
                let sampleYpos = sampler.uvSampler(u: u + 1/4, v: v)
                let sampleYneg = sampler.uvSampler(u: u + 1/4, v: v + 2/3)
                let k0 = Int(Face.PositiveY.rawValue * width * numBands + i*numBands+numBands*width*numFaces*j)
                let k1 = Int(Face.NegativeY.rawValue * width * numBands + i*numBands+numBands*width*numFaces*j)
                imgBuffer[k0] = sampleYpos.r
                imgBuffer[k0+1] = sampleYpos.g
                imgBuffer[k0+2] = sampleYpos.b
                imgBuffer[k1] = sampleYneg.r
                imgBuffer[k1+1] = sampleYneg.g
                imgBuffer[k1+2] = sampleYneg.b
            }
        }
    }
    
    /// Initializes a face of the cubemap with the given image
    func setFace(_ face: Face, image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let v = Float(j) / Float(height)
            for i in 0..<width {
                let u = Float(i) / Float(width)
                let sample = sampler.uvSampler(u: u, v: v)
                let faceOffset = face.rawValue * width * numBands
                let k = Int(faceOffset + i*numBands+numBands*width*numFaces*j)
                imgBuffer[k] = sample.r
                imgBuffer[k+1] = sample.g
                imgBuffer[k+2] = sample.b
            }
        }
    }
    
    /// Initializes 2 faces of the cubemap with the give image
    func setPanorama(_ side: Side, image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let v = Float(j) / Float(height)
            for i in 0..<2*width {
                let u = Float(i) / Float(2*width)
                let sample = sampler.uvSampler(u: u, v: v)
                let sideOffset = side.rawValue * 2 * width * numBands
                let k = Int(sideOffset + i*numBands+numBands*width*numFaces*j)
                imgBuffer[k] = sample.r
                imgBuffer[k+1] = sample.g
                imgBuffer[k+2] = sample.b
            }
        }
    }
    
    /// Pass a spherical projection map to initialize the cubemap
    func setSphericalProjectionMap(_ image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0..<height {
            let t = Float(j) / Float(height)
            let tc = 2.0 * t - 1.0
            for i in 0..<width {
                let s = Float(i) / Float(width)
                let sc = 2.0 * s - 1.0
                let posX = Spherical( v: Vector3(x: 1, y: -tc, z: -sc).normalize() )
                let negX = Spherical( v: Vector3(x: -1, y: -tc, z: sc).normalize() )
                let posY = Spherical( v: Vector3(x: sc, y: 1, z: tc).normalize() )
                let negY = Spherical( v: Vector3(x: sc, y: -1, z: -tc).normalize() )
                let posZ = Spherical( v: Vector3(x: sc, y: -tc, z: 1).normalize() )
                let negZ = Spherical( v: Vector3(x: -sc, y: -tc, z: -1).normalize() )
                let samples = [
                    sampler.uvSampler(u: negX.φ / PI2, v: negX.θ * PI_INV),
                    sampler.uvSampler(u: posZ.φ / PI2, v: posZ.θ * PI_INV),
                    sampler.uvSampler(u: posX.φ / PI2, v: posX.θ * PI_INV),
                    sampler.uvSampler(u: negZ.φ / PI2, v: negZ.θ * PI_INV),
                    sampler.uvSampler(u: posY.φ / PI2, v: posY.θ * PI_INV),
                    sampler.uvSampler(u: negY.φ / PI2, v: negY.θ * PI_INV)
                ]
                for face in 0...5 {
                    let faceOffset = face * Int(width * numBands)
                    let k = Int(faceOffset) + Int(i*numBands+numBands*width*numFaces*j)
                    imgBuffer[k] = samples[face].r
                    imgBuffer[k+1] = samples[face].g
                    imgBuffer[k+2] = samples[face].b
                }
            }
        }
    }
    
    // @todo replace by getPolarSampler; pass option to apply linear RGB conversion
    func polarSampler(θ: Float, φ: Float) -> Vector3 {
        let vec = Spherical(r: 1, θ: θ, φ: φ).ToVector3()
        let rgb = directionalSampler(vec)
        let color = Vector3(x: Float(rgb.0), y: Float(rgb.1), z: Float(rgb.2)) * (1.0/255.0)
        return color
    }
    
    func directionalSampler(_ vec: Vector3) -> (UInt8, UInt8, UInt8) {
        // Find major axis direction
        var maxAxis = Face.PositiveX
        var maxAxisValue = vec.x
        if -vec.x > maxAxisValue {
            maxAxis = Face.NegativeX
            maxAxisValue = -vec.x
        }
        if vec.y > maxAxisValue {
            maxAxis = Face.PositiveY
            maxAxisValue = vec.y
        }
        if -vec.y > maxAxisValue {
            maxAxis = Face.NegativeY
            maxAxisValue = -vec.y
        }
        if vec.z > maxAxisValue {
            maxAxis = Face.PositiveZ
            maxAxisValue = vec.z
        }
        if -vec.z > maxAxisValue {
            maxAxis = Face.NegativeZ
            maxAxisValue = -vec.z
        }
        var sc : Float = 0
        var tc : Float = 0
        switch maxAxis {
        case Face.PositiveX:
            sc = -vec.z; tc = -vec.y
            break
        case Face.NegativeX:
            sc = vec.z; tc = -vec.y
            break
        case Face.PositiveY:
            sc = vec.x; tc = vec.z
            break
        case Face.NegativeY:
            sc = vec.x; tc = -vec.z
            break
        case Face.PositiveZ:
            sc = vec.x; tc = -vec.y
            break
        case Face.NegativeZ:
            sc = -vec.x; tc = -vec.y
            break
        }
        let s = ( sc/abs(maxAxisValue) + 1 ) / 2
        let t = ( tc/abs(maxAxisValue) + 1 ) / 2
        return uvSampler(face: maxAxis, u: s, v: t)
    }
    
    func uvSampler(face: Face, u: Float, v: Float) -> (UInt8, UInt8, UInt8) {
        let faceOffset = face.rawValue * width * numBands
        let i = Int( Float(width) * u ) % width
        let j = Int( Float(height) * v ) % height
        let k = faceOffset + i*numBands+numBands*width*numFaces*j
        return (imgBuffer[k], imgBuffer[k+1], imgBuffer[k+2])
    }
    
}
