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
    let isFloat             : Bool
    var stride              : UInt = 0
    
    init(image: NSImage) {
        img = image
        imgCg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
        width = imgCg.width
        height = imgCg.height
        imgData = imgCg.dataProvider!.data
        bytesPerRow = imgCg.bytesPerRow
        bytesPerPixel = imgCg.bitsPerPixel / 8
        bitsPerComponent = imgCg.bitsPerComponent
        isFloat = imgCg.bitmapInfo.contains(.floatComponents)
        let supportsOutput = imgCg.colorSpace?.supportsOutput ?? false
        let wideRGB = imgCg.colorSpace?.isWideGamutRGB ?? false
        let size = CFDataGetLength(imgData)
        logDebug("\(imgCg.debugDescription), size = \(size), supportsOutput? \(supportsOutput), wideRGB? \(wideRGB), renderingIntent = \(imgCg.renderingIntent.rawValue), isFloat? \(isFloat)")
    }
    
    /// u, v: 0..1; top-left corner = (0,0) (in OpenGL it would be 0,1)
    func uvSampler<T: Number>(u: Float, v: Float) -> (r: T, g: T, b: T, a: T) {
        let k = getOffset(u: u, v: v)
        let ptr : UnsafePointer<UInt8> = CFDataGetBytePtr(imgData)
        switch bitsPerComponent {
        case 8:
            let a = bytesPerPixel == 4 ? ptr[k+3] : 255
            return (T(ptr[k]), T(ptr[k+1]), T(ptr[k+2]), T(a))
        case 16:
            let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: UInt16.self, capacity: 1)
            let a = bytesPerPixel == 8 ? p[3] : UInt16.max
            if MemoryLayout<T>.size == 1 {
                return (T(p[0] >> 8), T(p[1] >> 8), T(p[2] >> 8), T(a >> 8))
            }
            return (T(p[0]), T(p[1]), T(p[2]), T(a))
        case 32:
            if isFloat {
                let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: Float.self, capacity: 1)
                let a = bytesPerPixel == 16 ? p[3] : 1.0
                let c = (min(p[0], T.maxFloat), min(p[1], T.maxFloat), min(p[2], T.maxFloat), min(a, T.maxFloat))
                return (T(c.0), T(c.1), T(c.2), T(c.3))
            } else {
                let p = UnsafeRawPointer(ptr.advanced(by: k)).bindMemory(to: UInt32.self, capacity: 1)
                let a = bytesPerPixel == 16 ? p[3] : UInt32.max
                if MemoryLayout<T>.size == 1 {
                    return (T(p[0] >> 24), T(p[1] >> 24), T(p[2] >> 24), T(a >> 24))
                } else if MemoryLayout<T>.size == 2 {
                    return (T(p[0] >> 16), T(p[1] >> 16), T(p[2] >> 16), T(a >> 16))
                }
                return (T(p[0]), T(p[1]), T(p[2]), T(a))
            }
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
