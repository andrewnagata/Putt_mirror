//
//  Model.swift
//  Model
//
//  Created by Andrew Nagata on 8/4/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import AVFoundation

class Model {
    
    enum State {
        case Setup
        case CaptureEyes
        case Putting
        case Idle
    }

    var state:State = State.Idle
    
    var eyeline_height:CGFloat?
    var shoulder_height:CGFloat?
    
    static let shared = Model()
    
    init(){}
}
