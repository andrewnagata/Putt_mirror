//
//  TargetAlignViewController.swift
//
//  Created by Andrew Nagata on 12/27/21.
//  Copyright © 2021 rollyk. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import VideoToolbox
import Vision

class TargetAlignViewController: UIViewController {

    @IBAction func onDone(_ sender: Any) {
        //Transition to head alignment
        let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "eyeline_setup_id") as! EyelineSetupViewController
        
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}

