//
//  EyelineSetupViewController.swift
//
//  Created by Andrew Nagata on 12/27/21.
//  Copyright © 2021 rollyk. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import VideoToolbox
import Vision

class EyelineSetupViewController: UIViewController {
    
    @IBOutlet private var previewImageView: PoseImageView!
    private var currentFrame: CGImage?
    private var algorithm: Algorithm = .single
    private var poseBuilderConfiguration = PoseBuilderConfiguration()
    private var didRecieveFirstFrame: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For convenience, the idle timer is disabled to prevent the screen from locking.
        UIApplication.shared.isIdleTimerDisabled = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupAndBeginCapturingVideoFrames()
            
            PoseNet.shared.delegate = self
        }
        
        Model.shared.state = Model.State.Setup
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.previewImageView.alpha = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //VideoCapture.shared.stopCapturing {
            //super.viewWillDisappear(animated)
        //}
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        // Reinitilize the camera to update its output stream with the new orientation.
        setupAndBeginCapturingVideoFrames()
    }
    
    func fadeInVideo() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {self.previewImageView.alpha = 1.0})
    }
    
    private func setupAndBeginCapturingVideoFrames() {
        VideoCapture.shared.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }

            VideoCapture.shared.delegate = self
            
            VideoCapture.shared.startCapturing()
        }
    }
    
    private func puttingMode() {
        
        PoseNet.shared.delegate = nil
        VideoCapture.shared.delegate = nil
        
        let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "putting_id") as! PuttingViewController
        
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}

// MARK: - VideoCaptureDelegate

extension EyelineSetupViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        
        if !didRecieveFirstFrame {
            didRecieveFirstFrame = true
            fadeInVideo()
        }
        
        guard currentFrame == nil else {
            return
        }
        
        guard let image = capturedImage else {
            fatalError("Captured image is null")
        }
        
        var cropWidth = 640.0
        var cropHeight = (640.0/view.frame.width) * view.frame.height
        var xOffset = 0.0
        var yOffset = (480.0 - cropHeight) / 2
        if(UIDevice.current.orientation.isPortrait) {
            cropWidth = (640.0/view.frame.height) * view.frame.width
            cropHeight = 640.0
            xOffset = (480.0 - cropWidth) / 2
            yOffset = 0.0
        }
        
        let cropped = image.cropping(to: CGRect(x: xOffset, y: yOffset, width: cropWidth, height: cropHeight))
        
        currentFrame = cropped
        
        switch Model.shared.state {
        
            case Model.State.Setup:
                //Watch for the peace sign
                PoseNet.shared.predictPeace(cropped!)
                self.currentFrame = nil
                
            case Model.State.CaptureEyes:
                PoseNet.shared.predictPose(cropped!)
                
            default:
                //do nothing
                print("nothing")
        }
        
        previewImageView.show(frame: cropped!)
    }
}

// MARK: - PoseNetDelegate

extension EyelineSetupViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        defer {
            // Release `currentFrame` when exiting this method.
            self.currentFrame = nil
        }

        guard let currentFrame = currentFrame else {
            return
        }

        let poseBuilder = PoseBuilder(output: predictions,
                                      configuration: poseBuilderConfiguration,
                                      inputImage: currentFrame)

        let poses = algorithm == .single
            ? [poseBuilder.pose]
            : poseBuilder.poses
        
        //Eyeline position
        if(Model.shared.state == Model.State.CaptureEyes) {
            let interaface = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
            let orientation = AVCaptureVideoOrientation(deviceOrientation: interaface!)
            
            var scale = (view.frame.width/640.0)
            if orientation == AVCaptureVideoOrientation.portrait {
                scale = (view.frame.height/640.0)
            }
            
            //EYES
            let point1 = poseBuilder.pose.joints[.leftEye]?.position
            Model.shared.eyeline_height = point1!.y * scale
            //SHOULDERS
            let point2 = poseBuilder.pose.joints[.leftShoulder]?.position
            Model.shared.shoulder_height = point2!.y * scale
            
            Model.shared.state = Model.State.Idle
            
            SoundManager.shared.playConfirmationSound()
            
            puttingMode()
            
            return
        }
            
        previewImageView.show(poses: poses, with: currentFrame)
    }
    
    func poseNet(_ poseNet: PoseNet, didFindHandPose name: String, withImage image:CGImage) {
        
        switch name {
            case "Peace":
            Model.shared.state = Model.State.CaptureEyes
            poseNet.predictPose(image)
            //get vert pos of eyes
            //assign vert pos to eyelineIndicator
            break
            
            default: break
            //do nothing
        }
    }
}
