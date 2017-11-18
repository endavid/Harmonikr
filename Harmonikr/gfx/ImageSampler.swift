//
//  ImageSampler.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/7/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import AppKit       // NSImage

class ImageSampler {
    var img     : NSImage!
    var imgCg   : CGImage!
    var imgData : CFData!
    var width   : UInt = 0
    var height  : UInt = 0
    var stride  : UInt = 0
    
    init(image: NSImage) {
        img = image
        imgCg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
        width = UInt(imgCg.width)
        height = UInt(imgCg.height)
        imgData = imgCg.dataProvider!.data
        let size = CFDataGetLength(imgData)
        let expectedSizeRGB = Int(width * height * 3)
        let expectedSizeRGBA = Int(width * height * 4)
        switch size {
        case expectedSizeRGB:
            stride = 3
            break
        case expectedSizeRGBA:
            stride = 4
            break
        default:
            assert(false, "Unsupported format")
            break
        }
    }
    
    /// u, v: 0..1; top-left corner = (0,0) (in OpenGL it would be 0,1)
    func uvSampler(u: Float, v: Float) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        // @todo warp negative UVs
        let i = UInt( Float(width) * u ) % width
        let j = UInt( Float(height) * v ) % height
        let k = Int(stride * (width * j + i))
        let ptr : UnsafePointer<UInt8> = CFDataGetBytePtr(imgData)
        let a = stride == 4 ? ptr[k+3] : 255
        return (ptr[k], ptr[k+1], ptr[k+2], a)
    }
}
