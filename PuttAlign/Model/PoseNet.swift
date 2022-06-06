/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a facade to interact with the PoseNet model, includes input
 preprocessing and calling the model's prediction function.
*/

import CoreML
import Vision

protocol PoseNetDelegate: AnyObject {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput)
    func poseNet(_ poseNet: PoseNet, didFindHandPose name: String, withImage: CGImage)
}

class PoseNet: NSObject {
    /// The delegate to receive the PoseNet model's outputs.
    weak var delegate: PoseNetDelegate?

    /// The PoseNet model's input size.
    ///
    /// All PoseNet models available from the Model Gallery support the input sizes 257x257, 353x353, and 513x513.
    /// Larger images typically offer higher accuracy but are more computationally expensive. The ideal size depends
    /// on the context of use and target devices, typically discovered through trial and error.
    let modelInputSize = CGSize(width: 513, height: 513)

    /// The PoseNet model's output stride.
    ///
    /// Valid strides are 16 and 8 and define the resolution of the grid output by the model. Smaller strides
    /// result in higher-resolution grids with an expected increase in accuracy but require more computation. Larger
    /// strides provide a more coarse grid and typically less accurate but are computationally cheaper in comparison.
    ///
    /// - Note: The output stride is dependent on the chosen model and specified in the metadata. Other variants of the
    /// PoseNet models are available from the Model Gallery.
    let outputStride = 16

    /// The Core ML model that the PoseNet model uses to generate estimates for the poses.
    ///
    /// - Note: Other variants of the PoseNet model are available from the Model Gallery.
    private let poseNetMLModel: MLModel
    private let handPoseModel: PuttAlignmentClassifier
    
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var frameCounter = 0
    private let handPosePredictionInterval = 30
    
    static let shared: PoseNet = {
        let instance = PoseNet()
        return instance
    }()
    
    override init() {
        do {
            poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
            handPoseModel = try PuttAlignmentClassifier(configuration: .init())
            } catch {
                fatalError("Failed to load models. \(error.localizedDescription)")
            }
        
        handPoseRequest.maximumHandCount = 1;
    }
    /*
    init() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
        handPoseModel = try PuttAlignmentClassifier(configuration: .init())
        
        handPoseRequest.maximumHandCount = 1;
    }
    */
    /// Calls the `prediction` method of the PoseNet model and returns the outputs to the assigned
    /// `delegate`.
    ///
    /// - parameters:
    ///     - image: Image passed by the PoseNet model.
    func predictPose(_ image: CGImage) {
        //Skeleton and joints
        DispatchQueue.global(qos: .userInitiated).async {
            // Wrap the image in an instance of PoseNetInput to have it resized
            // before being passed to the PoseNet model.
            let input = PoseNetInput(image: image, size: self.modelInputSize)

            guard let prediction = try? self.poseNetMLModel.prediction(from: input) else {
                return
            }

            let poseNetOutput = PoseNetOutput(prediction: prediction,
                                              modelInputSize: self.modelInputSize,
                                              modelOutputStride: self.outputStride)
            
            DispatchQueue.main.async {
                self.delegate?.poseNet(self, didPredict: poseNetOutput)
            }
        }
    }
    
    func predictPeace(_ image: CGImage) {
    //HAND POSE
        self.frameCounter += 1
        if self.frameCounter % self.handPosePredictionInterval == 0 {
            DispatchQueue.global(qos: .userInteractive).async {
                
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([self.handPoseRequest])
                } catch {
                    assertionFailure("Hand Pose Request Failed: \(error)")
                }
                
                guard let handPoses = self.handPoseRequest.results, !handPoses.isEmpty else {
                    return
                }
                
                let handObservation = handPoses.first
                
                
                guard let keypointsMultiArray = try? handObservation?.keypointsMultiArray()
                else { fatalError() }
                
                do {
                    let handPosePrediction = try self.handPoseModel.prediction(poses: keypointsMultiArray)
                    
                    let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
                
                    if( confidence > 0.90 && handPosePrediction.label != "Idle")
                    {
                        DispatchQueue.main.async {
                            self.delegate?.poseNet(self, didFindHandPose: handPosePrediction.label, withImage: image)
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}
