//
//  SideCrossCubeMap.swift
//  Harmonikr
//
//  Created by David Gavilan on 2021/07/12.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import Foundation

class SideCrossCubeMap<T: Number>: CubeMap<T> {
    
    override var imageWidth: Int { get { return width * 4 } }
    override var imageHeight: Int { get { return height * 3 } }
    
    override func getArrayIndex(face: CubeMapFace, x: Int, y: Int) -> Int {
        let xcube: [CubeMapFace : Int] = [
            .NegativeX: 0,
            .PositiveZ: 1,
            .PositiveX: 2,
            .NegativeZ: 3,
            .PositiveY: 1,
            .NegativeY: 1
        ]
        let ycube: [CubeMapFace: Int] = [
            .NegativeX: 1,
            .PositiveZ: 1,
            .PositiveX: 1,
            .NegativeZ: 1,
            .PositiveY: 0,
            .NegativeY: 2
        ]
        let xOffset = xcube[face]! * width * numBands
        let yOffset = ycube[face]! * height * imageWidth * numBands
        let k = yOffset + xOffset + x*numBands+numBands*imageWidth*y
        return k
    }
}
