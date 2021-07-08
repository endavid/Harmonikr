//
//  ImageTypes.swift
//  Harmonikr
//
//  Created by David Gavilan on 2021/07/07.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import Foundation

enum BitDepth: String {
    case ldr = "LDR", hdr16 = "HDR16", hdr32 = "HDR32"
    
    func toBits() -> Int {
        switch self {
        case .ldr:
            return 8
        case .hdr16:
            return 16
        case .hdr32:
            return 32
        }
    }
}
