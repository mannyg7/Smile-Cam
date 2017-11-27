//
//  SmileCamViewController.swift
//  FinalProject
//
//  Created by Manmitha Gundampalli on 11/27/17.
//  Copyright © 2017 MannyG. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleMobileVision;

class SmileCamViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var faceDetector: GMVDetector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
        captureButton.clipsToBounds = true
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            fatalError("No video device found")
        }
        
        faceDetector = GMVDetector.init(ofType: GMVDetectorTypeFace,
                                       options: [GMVDetectorFaceLandmarkType: GMVDetectorFaceLandmark.all.rawValue,
                                                GMVDetectorFaceClassificationType: GMVDetectorFaceClassification.all.rawValue,
                                                GMVDetectorFaceTrackingEnabled: true])
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            // Get an instance of ACCapturePhotoOutput class
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            
            // Set the output on the capture session
            captureSession?.addOutput(capturePhotoOutput!)
            
            //Initialise the video preview layer and add it as a sublayer to the viewPreview view's layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            
            //start video capture
            captureSession?.startRunning()
        } catch {
            print(error)
        }
    }
    
    override func viewDidLayoutSubviews() {
        videoPreviewLayer?.frame = previewView.bounds
        if let previewLayer = videoPreviewLayer ,(previewLayer.connection?.isVideoOrientationSupported)! {
            previewLayer.connection?.videoOrientation = UIApplication.shared.statusBarOrientation.videoOrientation ?? .portrait
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTouchTakePicture(_ sender: Any) {
        // Make sure capturePhotoOutput is valid
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        
        // Get an instance of AVCapturePhotoSettings class
        let photoSettings = AVCapturePhotoSettings()
        
        // Set photo settings for our need
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        photoSettings.previewPhotoFormat = previewFormat
        // Call capturePhoto method by passing our photo settings and a delegate implementing AVCapturePhotoCaptureDelegate
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    

}

extension SmileCamViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        // Make sure we get some photo sample buffer
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        guard error == nil,
            let previewPhotoSampleBuffer = previewPhotoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        let deviceOrientation = UIDevice.current.orientation
        let devicePostion = AVCaptureDevice.Position.back
        var lastKnownDeviceOrientation = UIDeviceOrientation.landscapeLeft
        switch UIApplication.shared.statusBarOrientation {
        case UIInterfaceOrientation.landscapeRight:
            lastKnownDeviceOrientation = UIDeviceOrientation.landscapeLeft
            break;
        case UIInterfaceOrientation.landscapeLeft:
            lastKnownDeviceOrientation = UIDeviceOrientation.landscapeRight
            break;
        case UIInterfaceOrientation.portrait:
            lastKnownDeviceOrientation = UIDeviceOrientation.portrait
            break;
        case UIInterfaceOrientation.portraitUpsideDown:
            lastKnownDeviceOrientation = UIDeviceOrientation.portraitUpsideDown
            break;
        default:
            break;
        }
        let orientation = GMVUtility.imageOrientation(from: deviceOrientation, with: devicePostion, defaultDeviceOrientation: lastKnownDeviceOrientation)
        let options = [GMVDetectorImageOrientation:orientation.rawValue]
        let image: UIImage  = GMVUtility.sampleBufferTo32RGBA(previewPhotoSampleBuffer)
        // Check for smiling probability
        var smiling : Bool = true
        let Gfaces = self.faceDetector?.features(in: image, options: options) as? [GMVFaceFeature]
        for face: GMVFaceFeature in Gfaces! {
            if face.hasSmilingProbability && face.smilingProbability < 0.4 {
                print(face.smilingProbability)
                smiling = false;
            }
        }
        
        if smiling == true {
            // Convert photo same buffer to a jpeg image data by using AVCapturePhotoOutput
            guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                return
            }
            
            // Initialise an UIImage with our image data
            let capturedImage = UIImage.init(data: imageData , scale: 1.0)
            
            
            if let image = capturedImage {
                // Save our captured image to photos album
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
        
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }
}
