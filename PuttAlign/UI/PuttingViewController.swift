//
//  PuttingViewController.swift
//
//  Created by Andrew Nagata on 12/27/21.
//  Copyright © 2021 rollyk. All rights reserved.
//

import Foundation
import UIKit
import VideoToolbox
import Vision

class PuttingViewController: UIViewController {
    
    @IBOutlet private var previewImageView: PoseImageView!
    @IBOutlet weak var eyelineIndicator: UIView!
    @IBOutlet weak var eyelineLabel: UILabel!
    @IBOutlet weak var eyelineVertConstraint: NSLayoutConstraint!
    @IBOutlet weak var bodylineIndicator: UIView!
    @IBOutlet weak var bodylineVertConstraint: NSLayoutConstraint!
    @IBOutlet weak var bodylineLabel: UILabel!
    
    @IBOutlet weak var brightnessSlider: UISlider!
    private var currentFrame: CGImage?
    private var algorithm: Algorithm = .single
    private var poseBuilderConfiguration = PoseBuilderConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        //Assume video is up and running
        PoseNet.shared.delegate = self
        VideoCapture.shared.delegate = self
        
        Model.shared.state = Model.State.Putting
        
        eyelineVertConstraint.constant = Model.shared.eyeline_height!
        bodylineVertConstraint.constant = Model.shared.shoulder_height! - (bodylineIndicator.frame.height/2)
        
        let values = VideoCapture.shared.getTargetBias()
        brightnessSlider.minimumValue = values.min * 0.5
        brightnessSlider.maximumValue = values.max * 0.5
        brightnessSlider.setValue(values.current, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        eyelineIndicator.alpha = 0
        eyelineLabel.alpha = 0
        bodylineIndicator.alpha = 0
        bodylineLabel.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0.25, options: .curveEaseOut, animations: {self.eyelineIndicator.alpha = 0.75})
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {self.eyelineLabel.alpha = 1})
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {self.bodylineIndicator.alpha = 0.55})
        UIView.animate(withDuration: 0.5, delay: 0.75, options: .curveEaseOut, animations: {self.bodylineLabel.alpha = 1})
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
    
    @IBAction func onSlider(_ sender: UISlider) {
        let bias = Float(sender.value)
        VideoCapture.shared.setBias(bias: bias)
    }
    
    @IBAction func onEyeTouch(_ sender: Any) {
    
        PoseNet.shared.delegate = nil
        VideoCapture.shared.delegate = nil
        
        let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "eyeline_setup_id") as! EyelineSetupViewController
        
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    @IBAction func panView(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
     
        if let viewToDrag = sender.view {
            bodylineVertConstraint.constant = bodylineVertConstraint.constant + translation.y
            sender.setTranslation(CGPoint(x: 0, y: 0), in: viewToDrag)
        }
    }
}

// MARK: - VideoCaptureDelegate

extension PuttingViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        
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
        
            case Model.State.Idle:
                self.currentFrame = nil
            
            case Model.State.Putting:
                PoseNet.shared.predictPose(cropped!)
                
            default:
                //do nothing
                print("nothing")
        }
        
        previewImageView.show(frame: cropped!)
    }
}

// MARK: - PoseNetDelegate

extension PuttingViewController: PoseNetDelegate {
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
        
        previewImageView.show(poses: poses, with: currentFrame)
    }
    
    func poseNet(_ poseNet: PoseNet, didFindHandPose name: String, withImage image:CGImage) {

    }
}
