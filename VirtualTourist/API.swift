//
//  API.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/19/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation


struct API {
    
    //static let session = NSURLSession.sharedSession()
    static func buildTask(request : NSURLRequest, completionHandler : (result : NSData!, error : NSError?) -> Void ) -> NSURLSessionTask {
        let task = Flickr.sharedInstance().session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                completionHandler(result: nil, error: error)
            } else {
                completionHandler(result: data, error: nil)
            }
        }
        task.resume()
        return task
    }
    
    static func getRequest(baseURL : String, method : String) -> NSURLRequest {
        let url = buildURL(baseURL, method: method)
        return NSURLRequest(URL: url)
    }
    
    static func buildURL(baseURL : String, method : String) -> NSURL {
        let urlString = baseURL + method
        return NSURL(string: urlString)!
    }
    
    static func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }

}