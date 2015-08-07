//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/20/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import MapKit

class Flickr : NSObject {
    
    static let BASE_URL = "https://api.flickr.com/services/rest/"
    static let KEY = "997f1bef3193d00b266b79bc54372525"
    static let SECRET = "ad1eda3354dc3110"
    static let url = "".join(Flickr.APIComponents)
    
    static let APIComponents = [
        Flickr.BASE_URL,
        Flickr.Methods.Photos.Search,
    ]
    
    struct Methods {
        
        struct Photos {
            static let Search = "?method=flickr.photos.search"
            
            struct Geo {
                static let PhotosForLocation = "?method=flickr.photos.geo.photosForLocation"
            }
        }
        struct Parameters {
            static let EXTRAS = "url_m"
            static let DATA_FORMAT = "json"
            static let NO_JSON_CALLBACK = "1"
        }
    }
    
    struct Notifications {
        
        static let PhotosLoadedForPin = "PhotosLoadedForPinNotification"
        static let PhotoLoaded = "PhotoLoadedNotification"
    }
    
    struct Download {
        enum Status {
            case Idle, Loading, Done
        }
    }
    
    class func buildURLWith(coordinate : CLLocationCoordinate2D, radius : Int, photosPerPage : Int, and page: Int) -> String {
        var urlComponents = [
            Flickr.url,
            "api_key=\(Flickr.KEY)",
            "format=\(Flickr.Methods.Parameters.DATA_FORMAT)",
            "nojsoncallback=\(Flickr.Methods.Parameters.NO_JSON_CALLBACK)",
            "lat=\(coordinate.latitude)",
            "lon=\(coordinate.longitude)",
            "radius=\(radius)",
            "per_page=\(photosPerPage)",
            "page=\(page)"
        ]
        return "&".join(urlComponents)
    }
    
    class func buildImageURLWith(photo : [String : AnyObject]) -> String {
        var imageURLComponents = [
            "https://farm",
            String(photo["farm"] as! Int),
            ".staticflickr.com/",
            photo["server"] as! String,
            "/",
            photo["id"] as! String,
            "_",
            photo["secret"] as! String,
            "_z.jpg"]
        
        return "".join(imageURLComponents)
    }

    
    /**
        MARK: sharedInstance of the Flickr class and the cache
              to store and retrieve Flickr images quickly
    **/
    class func sharedInstance() -> Flickr {
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        return Singleton.sharedInstance
    }
    
}