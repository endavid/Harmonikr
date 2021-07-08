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
    let maxValue            : UInt32
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
        maxValue = bitsPerComponent == 8 ? 255 : bitsPerComponent == 16 ? UInt32(UInt16.max) : UInt32.max
        let size = CFDataGetLength(imgData)
        logDebug("CGImage: \(width)x\(height), bitsPerComponent \(bitsPerComponent), bitsPerPixel \(imgCg.bitsPerPixel), bytesPerRow \(bytesPerRow), size \(size)")
    }
    
    /// u, v: 0..1; top-left corner = (0,0) (in OpenGL it would be 0,1)
    func uvSampler<T: UnsignedInteger & FixedWidthInteger>(u: Float, v: Float) -> (r: T, g: T, b: T, a: T) {
        let k = getOffset(u: u, v: v)
        let ptr : UnsafePointer<UInt8> = CFDataGetBytePtr(imgData)
        switch bitsPerComponent {
        case 8:
            let a = bytesPerPixel == 4 ? ptr[k+3] : 255
            return (T(ptr[k]), T(ptr[k+1]), T(ptr[k+2]), T(a))
        case 16:
            let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: UInt16.self, capacity: 1)
            let a = bytesPerPixel == 8 ? p[3] : UInt16.max
            let m = UInt32(T.max)
            let rm = m & UInt32(p[0])
            let gm = m & UInt32(p[1])
            let bm = m & UInt32(p[2])
            let am = m & UInt32(a)
            return (T(rm), T(gm), T(bm), T(am))
        case 32:
            let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: UInt32.self, capacity: 1)
            let a = bytesPerPixel == 16 ? p[3] : UInt32.max
            let m = UInt32(T.max)
            return (T(m & p[0]), T(m & p[1]), T(m & p[2]), T(m & a))
        default:
            return (0,0,0,0)
        }
    }
    
    private func getOffset(u: Float, v: Float) -> Int {
        // @todo warp negative UVs
        let i = Int( Float(width) * u ) % width
        let j = Int( Float(height) * v ) % height
        let k = bytesPerRow * j + bytesPerPixel * i
        return k
    }
}
