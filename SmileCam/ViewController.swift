//
//  ViewController.swift
//  FinalProject
//
//  Created by Manmitha Gundampalli on 11/27/17.
//  Copyright © 2017 MannyG. All rights reserved.
//

/*
 The view Controller for the main page that
 allows for pictuer selection and label overlay
 */

import UIKit
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController();
    let session = URLSession.shared
    var responseJSON: JSON = []
    var binaryImageData: String = "";
    // Google API related info
    var googleAPIKey = ""
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    @IBOutlet var submitImageButton: UIBarButtonItem!
    
    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet var attributesButton: UIBarButtonItem!
    
    @IBAction func submitPicture(_ sender: UIBarButtonItem) {
        createRequest(with: binaryImageData)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.navigationItem.rightBarButtonItem = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /*
     Selection of picture from photo album
     */
    @IBAction func loadImageButton(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    /*
     Selection of picture from camera
     */
    @IBAction func takeImageButton(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    /*MARK: - Saving Image here*/
    func save(_ sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(imgView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    /*Add image to Library*/
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    /*
     Converts the selected image to base64
     and shows on the image on the screen
     */
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let chosenImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            imgView.contentMode = .scaleAspectFit
            imgView.image = chosenImage
            imgView.subviews.forEach({ $0.removeFromSuperview() })
            self.navigationItem.rightBarButtonItem = self.submitImageButton
            binaryImageData = base64EncodeImage(chosenImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    /*
     Conversion of image to resized image representation.
     */
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = image.pngData()
        if ((imagedata?.count)! > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            UIGraphicsBeginImageContext(newSize)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            let resizedImage = newImage!.pngData()
            UIGraphicsEndImageContext()
            imagedata = resizedImage
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    /*
     Request sent to google API
     */
    func createRequest(with imageBase64: String) {
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "TEXT_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "LANDMARK_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "LOGO_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "FACE_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "WEB_DETECTION",
                        "maxResults": 10
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonRequest)
        guard let data = try? jsonObject.rawData() else {
            return
        }
        request.httpBody = data

        DispatchQueue.global().async {
            let task: URLSessionDataTask = self.session.dataTask(with: request) { (data, response, error) in
                guard let data = data, error == nil else {
                    return
                }
                self.getResults(data)
            }
            task.resume()
        }
    }
    
    /*
     Results from API taken and results shown on picture
     */
    func getResults(_ dataJSON: Data) {
        DispatchQueue.main.async(execute: {
            self.view.isUserInteractionEnabled = true
            let json = try! JSON(data: dataJSON)
            let errorObj: JSON = json["error"]
            if (errorObj.dictionaryValue != [:]) {
                print("Error code \(errorObj["code"]): \(errorObj["message"])")
            } else {
                self.responseJSON = json["responses"][0]
                self.navigationItem.rightBarButtonItem = self.attributesButton
                
                let scaleW = (self.imgView.frame.size.width)/(self.imgView.image?.size.width)!
                let scaleH = (self.imgView.frame.size.height)/(self.imgView.image?.size.height)!
                let aspect = fmin(scaleH, scaleW)
                let rw = (self.imgView.image?.size.width)! * aspect
                let rh = (self.imgView.image?.size.height)! * aspect
                let imgx = ((self.imgView.frame.size.width - rw) / 2)
                let imgy = ((self.imgView.frame.size.height - rh) / 2)
                
                
                
                let landmarkAnnotations: JSON = self.responseJSON["landmarkAnnotations"]
                let numLabels: Int = landmarkAnnotations.count
                if numLabels > 0 {
                    for index in 0..<numLabels {
                        let labelTxt = landmarkAnnotations[index]["description"].stringValue
                        let xval = landmarkAnnotations[index]["boundingPoly"]["vertices"][0]["x"].numberValue as! CGFloat * aspect
                        let yVal = landmarkAnnotations[index]["boundingPoly"]["vertices"][0]["y"].numberValue as! CGFloat * aspect
                        let label = UILabel(frame: CGRect(x: imgx + xval,
                                                          y: imgy + yVal,
                                                          width: 20,
                                                          height: 5))
                        label.textColor = UIColor.red
                        label.textAlignment = NSTextAlignment.center
                        label.text = labelTxt
                        label.sizeToFit()
                        label.layer.borderWidth = 1.0
                        label.layer.cornerRadius = 5
                        label.layer.shadowColor = UIColor.black.cgColor
                        label.layer.shadowRadius = 3.0
                        label.layer.shadowOpacity = 3.0
                        label.layer.shadowOffset = CGSize(width: 4, height: 4)
                        let gesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.labelDrag(_:)))
                        self.imgView.isUserInteractionEnabled = true
                        label.isUserInteractionEnabled = true
                        label.addGestureRecognizer(gesture)
                        self.imgView.addSubview(label)
                    }
                }
                
                let textAnnotations: JSON = self.responseJSON["textAnnotations"]
                let numLabelsText: Int = textAnnotations.count
                if numLabelsText > 0 {
                    for index in 0..<numLabelsText {
                        let labelTxt = textAnnotations[index]["description"].stringValue
                        let xval = textAnnotations[index]["boundingPoly"]["vertices"][0]["x"].numberValue as! CGFloat * aspect
                        let yVal = textAnnotations[index]["boundingPoly"]["vertices"][0]["y"].numberValue as! CGFloat * aspect
                        let label = UILabel(frame: CGRect(x: imgx + xval,
                                                          y: imgy + yVal,
                                                          width: 5,
                                                          height: 2))
                        label.textColor = UIColor.blue
                        label.textAlignment = NSTextAlignment.center
                        label.text = labelTxt
                        label.sizeToFit()
                        label.layer.backgroundColor = UIColor.white.cgColor
                        let gesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.labelDrag(_:)))
                        self.imgView.isUserInteractionEnabled = true
                        label.isUserInteractionEnabled = true
                        label.addGestureRecognizer(gesture)
                        self.imgView.addSubview(label)
                    }
                }
                
                let logoAnnotations: JSON = self.responseJSON["logoAnnotations"]
                let numLabelsLogos: Int = logoAnnotations.count
                if numLabelsLogos > 0 {
                    for index in 0..<numLabelsLogos {
                        let labelTxt = logoAnnotations[index]["description"].stringValue
                        let xval = logoAnnotations[index]["boundingPoly"]["vertices"][0]["x"].numberValue as! CGFloat * aspect
                        let yVal = logoAnnotations[index]["boundingPoly"]["vertices"][0]["y"].numberValue as! CGFloat * aspect
                        let label = UILabel(frame: CGRect(x: imgx + xval,
                                                          y: imgy + yVal,
                                                          width: 50,
                                                          height: 20))
                        label.textColor = UIColor.white
                        label.textAlignment = NSTextAlignment.center
                        label.text = labelTxt
                        label.sizeToFit()
                        label.layer.borderWidth = 1.0
                        label.layer.cornerRadius = 5
                        label.layer.shadowColor = UIColor.black.cgColor
                        label.layer.shadowRadius = 5.0
                        label.layer.shadowOpacity = 9.0
                        label.layer.shadowOffset = CGSize(width: 4, height: 4)
                        self.imgView.addSubview(label)
                    }
                }
                
                let faceAnnotations: JSON = self.responseJSON["faceAnnotations"]
                print(faceAnnotations)
                let numLabelsFace = faceAnnotations.count
                if numLabelsFace > 0 {
                    for index in 0..<numLabelsFace {
                        let xval = faceAnnotations[index]["boundingPoly"]["vertices"][0]["x"].numberValue as! CGFloat * aspect
                        let yVal = faceAnnotations[index]["boundingPoly"]["vertices"][0]["y"].numberValue as! CGFloat * aspect
                        let xval1 = faceAnnotations[index]["boundingPoly"]["vertices"][1]["x"].numberValue as! CGFloat * aspect
                        let yVal1 = faceAnnotations[index]["boundingPoly"]["vertices"][2]["y"].numberValue as! CGFloat * aspect
                        let h = (yVal1 - yVal)
                        let w = (xval1 - xval)
                            let label = UILabel(frame: CGRect(x: imgx + xval,
                                                          y: imgy + yVal,
                                                          width: w,
                                                          height: h))
                            label.textColor = UIColor.black
                            label.textAlignment = NSTextAlignment.center
                            label.layer.borderWidth = 2.0
                            label.layer.cornerRadius = 5
                            label.layer.shadowColor = UIColor.black.cgColor
                            label.layer.shadowRadius = 5.0
                            label.layer.shadowOpacity = 9.0
                            label.layer.shadowOffset = CGSize(width: 4, height: 4)
                            label.tag = 1
                            self.imgView.addSubview(label)
                    }
                }
                
            }
        })
    }
    
    @objc func labelDrag(_ gesture: UIPanGestureRecognizer) {
        let lbl = gesture.view
        let trans = gesture.translation(in: self.view)
        lbl?.center = CGPoint(x: (lbl?.center.x)! + trans.x , y: (lbl?.center.y)! + trans.y)
        gesture.setTranslation(CGPoint.zero, in: lbl)
    }
    
    /*
     Segue for the attributes
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "Show Attributes",
                let attributeTableView = segue.destination as? AttributesTableViewController
            {
                attributeTableView.responseJSON = self.responseJSON
            }
        }

    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

