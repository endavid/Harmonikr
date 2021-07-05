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
    let img                 : NSImage!
    let imgCg               : CGImage!
    let imgData             : CFData!
    let width               : Int
    let height              : Int
    let bitsPerComponent    : Int
    let bytesPerRow         : Int
    let bytesPerPixel       : Int
    var stride  : UInt = 0
    
    init(image: NSImage) {
        img = image
        imgCg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
        width = imgCg.width
        height = imgCg.height
        imgData = imgCg.dataProvider!.data
        bytesPerRow = imgCg.bytesPerRow
        bytesPerPixel = imgCg.bitsPerPixel / 8
        bitsPerComponent = imgCg.bitsPerComponent
        let size = CFDataGetLength(imgData)
        logDebug("CGImage: \(width)x\(height), bitsPerComponent \(bitsPerComponent), bitsPerPixel \(imgCg.bitsPerPixel), bytesPerRow \(bytesPerRow), size \(size)")
    }
    
    /// u, v: 0..1; top-left corner = (0,0) (in OpenGL it would be 0,1)
    func uvSampler(u: Float, v: Float) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        // @todo warp negative UVs
        // @todo support HDR images
        let i = Int( Float(width) * u ) % width
        let j = Int( Float(height) * v ) % height
        let k = bytesPerRow * j + bytesPerPixel * i
        let ptr : UnsafePointer<UInt8> = CFDataGetBytePtr(imgData)
        switch bitsPerComponent {
        case 8:
            let a = bytesPerPixel == 4 ? ptr[k+3] : 255
            return (ptr[k], ptr[k+1], ptr[k+2], a)
        case 16:
            let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: UInt16.self, capacity: 1)
            let a = bytesPerPixel == 8 ? ptr[k+3] : 255
            return (UInt8(p[0] >> 8), UInt8(p[1] >> 8), UInt8(p[2] >> 8), a)
        case 32:
            let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: UInt32.self, capacity: 1)
            let a = bytesPerPixel == 16 ? ptr[k+3] : 255
            return (UInt8(p[0] >> 24), UInt8(p[1] >> 24), UInt8(p[2] >> 24), a)
        default:
            return (0,0,0,0)
        }
    }
}
