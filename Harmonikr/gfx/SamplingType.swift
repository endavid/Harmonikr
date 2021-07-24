//
//  SamplingType.swift
//  Harmonikr
//
//  Created by David Gavilan on 2021/07/24.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import Foundation

enum SamplingType {
    /// point sampling: picks the closest pixel
    case point
    /// linear sampling: interpolates 4 nearby pixels
    case linear
}
