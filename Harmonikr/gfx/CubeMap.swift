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
    let width       : UInt = 64
    let height      : UInt = 64
    let bands       : UInt = 3     ///< R,G,B
    let sides       : UInt = 6
    var imgBuffer   : Array<UInt8>!
    
    init() {
        let bufferLength : Int = (Int)(getBufferLength())
        imgBuffer = Array<UInt8>(count: bufferLength, repeatedValue: 0)
    }
    
    func getBufferLength() -> (UInt) {
        return width * height * bands * sides
    }
    
    func setFace(face: UInt, image: NSImage) {
        let sampler = ImageSampler(image: image)
        for j in 0...(height-1) {
            for i in 0...(width-1) {
                let u = Float(i) / Float(width)
                let v = Float(j) / Float(height)
                let sample = sampler.uvSampler(u: u, v: v)
                let faceOffset = face * width * bands
                let k = Int(faceOffset + i*bands+bands*width*sides*j)
                imgBuffer[k] = sample.r
                imgBuffer[k+1] = sample.g
                imgBuffer[k+2] = sample.b
            }
        }
    }
    
}