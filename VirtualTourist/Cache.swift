//
//  Cache.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/25/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Cache {
    
    func downloadImage(imageURL: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let request = NSURLRequest(URL: NSURL(string: imageURL)!)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        return task
    }

    func imageForIdentifier(identifier : String?) -> UIImage? {
        
        if (identifier == nil) || (identifier!.isEmpty) {
            return nil
        }
        let path = formatPathForIdentifier(identifier!)
        var imageData : NSData?
        
        if let image = NSData(contentsOfFile: path) {
            return UIImage(data: image)
        } else {
            return nil
        }
    }
    
    func saveImage(image : UIImage?, identifier : String) {
        let filePath = formatPathForIdentifier(identifier)
        
        if image == nil {
            NSFileManager.defaultManager().removeItemAtPath(filePath, error: nil)
            return
        }
        let imageData = UIImagePNGRepresentation(image!)
        imageData.writeToFile(filePath, atomically: true)
    }
    
    /**
        MARK: Delete the image by storing nil where the image
              was originally found.
    **/
    func deleteImage(identifier : String) {
        saveImage(nil, identifier: identifier)
    }
    
    
    func formatPathForIdentifier(identifer : String) -> String {
        let documentDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        let pathURL = documentDirectory.URLByAppendingPathComponent(replaceCharactersInString(identifer))
        return pathURL.path!
        
    }
    
    func replaceCharactersInString(string : String) -> String {
        return string.stringByReplacingOccurrencesOfString("/", withString: "-", options: NSStringCompareOptions.LiteralSearch)
    }
    
    class func sharedInstance() -> Cache {
        struct Singleton {
            static var sharedInstance = Cache()
        }
        return Singleton.sharedInstance
    }
    
}

