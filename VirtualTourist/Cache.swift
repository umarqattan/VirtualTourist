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
    
    var cache = NSCache()
    
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
        } else {
            let path = formatPathForIdentifier(identifier!)
            var imageData : NSData?
            
            if let image = cache.objectForKey(path) as? UIImage {
                return image
            } else if let imageData = NSData(contentsOfFile: path) {
                return UIImage(data: imageData)
            } else {
                return nil
            }
        }
    }
    
    func saveImage(image : UIImage?, identifier : String) {
        let filePath = formatPathForIdentifier(identifier)
        
        if image == nil {
            cache.removeObjectForKey(filePath)
            NSFileManager.defaultManager().removeItemAtPath(filePath, error: nil)
            return
        } else {
            cache.setObject(image!, forKey: filePath)
            let imageData = UIImagePNGRepresentation(image!)
            imageData.writeToFile(filePath, atomically: true)
        }
    }
    
    func deleteImage(identifier : String) {
        let filePath = formatPathForIdentifier(identifier)
        
        cache.removeObjectForKey(filePath)
        var error : NSError? = nil
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
            
            if let error = error {
                println("Could not remove item at path: \(filePath)")
            }
        }
    }
    
    func deleteImageFromStore(identifier : String) {
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

