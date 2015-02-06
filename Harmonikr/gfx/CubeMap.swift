//
//  CubeMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2/6/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation

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
    
    
}