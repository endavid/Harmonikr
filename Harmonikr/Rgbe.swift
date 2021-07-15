//
//  Rgbe.swift
//  Harmonikr
//
//  Created by David Gavilan on 2021/07/14.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import Foundation

typealias Rgbe = (r: UInt8, g: UInt8, b: UInt8, e: UInt8)

class RgbeWriter {
    static let whiteEfficacy: Double = 179.0 / 255.0
    
    static func toRadianceData<T: Number>(width: Int, height: Int, imgData: Array<T>) -> Data {
        // ref. https://github.com/LuminanceHDR/LuminanceHDR/blob/master/src/Libpfs/io/rgbewriter.cpp
        var data = Data()
        // header information
        data += toData("#?RADIANCE\n")
        data += toData("# Harmonikr writer\n")
        data += toData("FORMAT=32-bit_rle_rgbe\n")
        data += toData("\n")
        // image size
        data += toData("-Y \(height) +X \(width)\n")
        // binary image data:
        //   per scan line:
        //     old format:
        //       r,g,b,e 8 bit data (at least 1 of r,g,b > 127, or all 0)
        //       1,1,1,x = old rle, repeat prev color X times
        //     new rle format: (only used if 8< image width < 32767?
        //       2,2,h,l (h<127) scanline length = (256 * h + l)
        //         1 scanline each for r,g,b,e, rle encoded as
        //            run octet: >128 = repeat next octet (n & 127) times
        //                       <128 = copy next N octets
        //            repeat until LENGTH octets, then repeat for next component
        let header: [UInt8] = [2, 2, UInt8(width >> 8), UInt8(width & 0xFF)]
        let headerData = Data(header)
        var scanlineR = [UInt8].init(repeating: 0, count: width)
        var scanlineG = [UInt8].init(repeating: 0, count: width)
        var scanlineB = [UInt8].init(repeating: 0, count: width)
        var scanlineE = [UInt8].init(repeating: 0, count: width)
        for y in 0..<height {
            data += headerData
            // each channel is encoded separately
            for x in 0..<width {
                let k = y * width * 3 + x * 3
                let r = imgData[k].asFloat / T.norm
                let g = imgData[k+1].asFloat / T.norm
                let b = imgData[k+2].asFloat / T.norm
                let p = rgb2rgbe(r, g, b)
                scanlineR[x] = p.r
                scanlineG[x] = p.g
                scanlineB[x] = p.b
                scanlineE[x] = p.e
            }
            data += RLE(scanlineR)
            data += RLE(scanlineG)
            data += RLE(scanlineB)
            data += RLE(scanlineE)
        }
        return data
    }
    
    static func toData(_ s: String) -> Data {
        return s.data(using: .ascii) ?? Data()
    }
        
    static func rgb2rgbe(_ cr: Float, _ cg: Float, _ cb: Float) -> Rgbe {
        let r = Double(cr) / whiteEfficacy
        let g = Double(cg) / whiteEfficacy
        let b = Double(cb) / whiteEfficacy
        let maxValue = max(r, g, b)
        if (maxValue < 1e-32) {
            return (0, 0, 0, 0)
        }
        let (value, exponent) = frexp(maxValue)
        let v = value * 256.0 / maxValue
        return (UInt8(v * r), UInt8(v * g), UInt8(v * b), UInt8(exponent + 128))
    }
    static func RLE(_ scanline: [UInt8]) -> Data {
        var data = Data()
        var index = 0
        // run octet: >128 = repeat next octet (n & 127) times
        //            <128 = copy next N octets
        // repeat until LENGTH octets, then repeat for next component
        while index < scanline.count {
            var run_start = 0
            var peek = 0
            var run_len = 0
            while run_len <= 4 && peek < 128 && ((index + peek) < scanline.count) {
                run_start = peek
                run_len = 0
                while (run_len < 127) && (run_start + run_len < 128) &&
                        (index + peek < scanline.count) &&
                       (scanline[index + run_start] == scanline[index + peek]) {
                    peek += 1
                    run_len += 1
                }
            }
            if run_len > 4 {
                // write a non run: scanline[0] to scanline[run_start]
                if run_start > 0 {
                    var buf = [UInt8].init(repeating: 0, count: run_start + 1)
                    buf[0] = UInt8(run_start)
                    for i in 0..<run_start {
                        buf[i + 1] = scanline[index + i]
                    }
                    data += Data(buf)
                }
                // write a run: scanline[run_start], run_len
                let buf: [UInt8] = [
                    UInt8(128 + run_len),
                    scanline[index + run_start]
                ]
                data += Data(buf)
            } else {
                // write a non run: scanline[0] to scanline[peek]
                var buf = [UInt8].init(repeating: 0, count: peek + 1)
                buf[0] = UInt8(peek)
                for i in 0 ..< peek {
                    buf[i + 1] = scanline[index + i]
                }
                data += Data(buf)
            }
            index += peek
        }
        if index != scanline.count {
            NSLog("RGBE: difference in size while writing RLE scanline")
        }
        return data
    }
}
