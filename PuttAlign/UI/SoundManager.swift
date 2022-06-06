//
//  SoundManager.swift
//
//  Created by Andrew Nagata on 12/30/21.
//  Copyright © 2021 rollyk. All rights reserved.
//

import Foundation
import AVFoundation

class SoundManager: NSObject {
    
    private var sound: AVAudioPlayer?
    
    static let shared: SoundManager = {
        let instance = SoundManager()
        // setup code
        return instance
    }()
    
    public func playConfirmationSound() {
        let path = Bundle.main.path(forResource: "confirm_peace.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        do {
            sound = try AVAudioPlayer(contentsOf: url)
            sound?.play()
        } catch {
            print("Can't play sound file");
        }
    }
}
