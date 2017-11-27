//
//  AttributesTableViewController.swift
//  FinalProject
//
//  Created by Manmitha Gundampalli on 11/28/17.
//  Copyright © 2017 MannyG. All rights reserved.
//


import UIKit
import SwiftyJSON

/*
 TabelView for Attributes.
 */
class AttributesTableViewController: UITableViewController {
    
    /*
     Response JSON set from ViewController
     */
    public var responseJSON: JSON? {
        didSet {
            if responseJSON != nil {
                loadAttributes()
                tableView.reloadData()
                title = "Attributes"
            }
        }
    }
    
    /*
     Array for attribute values
     */
    private var attributes = [AttributeValues] ()
    
    private struct AttributeValues{
        var attributesArray: [String]
        var attributeType: String
        var attributesScoresArray: [String]?
        
        init(attributesArray: [String], attributeType: String) {
            self.attributeType = attributeType
            self.attributesArray = attributesArray
        }
        
        init(attributesArray: [String], attributeType: String, attributesScoresArray: [String]) {
            self.attributeType = attributeType
            self.attributesArray = attributesArray
            self.attributesScoresArray = attributesScoresArray
        }
    }
    
    /*
     Loads all the attributes from the JSON
    */
    private func loadAttributes() {
        if responseJSON != [] {
            let labelAnnotations: JSON = responseJSON!["labelAnnotations"]
            var numLabels: Int = labelAnnotations.count
            var labels = [String] ()
            var scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = labelAnnotations[index]["description"].stringValue
                    let score = labelAnnotations[index]["score"].stringValue
                    labels.append(label)
                    scores.append(score)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Label Annotations", attributesScoresArray: scores))
            }
            
            let landmarkAnnotations: JSON = responseJSON!["landmarkAnnotations"]
            numLabels = landmarkAnnotations.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = landmarkAnnotations[index]["description"].stringValue
                    let score = labelAnnotations[index]["score"].stringValue
                    labels.append(label)
                    scores.append(score)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Landmark Annotations", attributesScoresArray: scores))
            }
            
            let textAnnotations: JSON = responseJSON!["textAnnotations"]
            numLabels = textAnnotations.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = textAnnotations[index]["description"].stringValue
                    let score = labelAnnotations[index]["score"].stringValue
                    labels.append(label)
                    scores.append(score)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Text Annotations", attributesScoresArray: scores))
            }
            
            let logoAnnotations: JSON = responseJSON!["logoAnnotations"]
            numLabels = logoAnnotations.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = logoAnnotations[index]["description"].stringValue
                    let score = labelAnnotations[index]["score"].stringValue
                    labels.append(label)
                    scores.append(score)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Logo Annotations", attributesScoresArray: scores))
            }
            
            var urls: JSON = responseJSON!["webDetection"]["partialMatchingImages"]
            numLabels = urls.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = urls[index]["url"].stringValue
                    labels.append(label)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Web Partial Matching Images"))
            }
            
            urls = responseJSON!["webDetection"]["visuallySimilarImages"]
            numLabels = urls.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = urls[index]["url"].stringValue
                    labels.append(label)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Web Similar Images"))
            }
            
            urls = responseJSON!["webDetection"]["pagesWithMatchingImages"]
            numLabels = urls.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = urls[index]["url"].stringValue
                    labels.append(label)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Web Pages With Matching Images"))
            }
            
            urls = responseJSON!["webDetection"]["webEntities"]
            numLabels = urls.count
            labels = [String] ()
            scores = [String] ()
            if numLabels > 0 {
                for index in 0..<numLabels {
                    let label = urls[index]["description"].stringValue
                    let score = labelAnnotations[index]["score"].stringValue
                    labels.append(label)
                    scores.append(score)
                }
                attributes.append(AttributeValues(attributesArray: labels, attributeType: "Web Annotations", attributesScoresArray: scores))
            }
        }
        
    }

    // MARK: - Table view data source
    /*
     Shows the number in each section.
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return attributes.count
    }

    /*
     Shows the row sections
     */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return attributes[section].attributesArray.count
    }

    /*
     Sets the cell data
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Labels")
        cell.textLabel?.text = attributes[indexPath.section].attributesArray[indexPath.row]
        if let scores = attributes[indexPath.section].attributesScoresArray,
            scores[indexPath.row] != ""{
            cell.detailTextLabel?.text = "Score: \(scores[indexPath.row])"
        }
        return cell
    }
    
    /*
     Sets row header
     */
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return attributes[section].attributeType
    }
    
    /*
     Opens safari for web links
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if attributes[indexPath.section].attributeType == "Web Similar Images" ||
           attributes[indexPath.section].attributeType == "Web Partial Matching Images" ||
            attributes[indexPath.section].attributeType == "Web Pages With Matching Images"{
            let urlText = attributes[indexPath.section].attributesArray[indexPath.row]
               if let url = URL(string:urlText) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    

    


}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
