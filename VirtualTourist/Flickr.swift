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
            "{api_key}",
            "{format}",
            "{nojsoncallback}",
            "{latitude}",
            "{longitude}",
            "{radius}",
            "{per_page}",
            "{page}"
        ]
        urlComponents[1] = "api_key=\(Flickr.KEY)"
        urlComponents[2] = "format=\(Flickr.Methods.Parameters.DATA_FORMAT)"
        urlComponents[3] = "nojsoncallback=\(Flickr.Methods.Parameters.NO_JSON_CALLBACK)"
        urlComponents[4] = "lat=\(coordinate.latitude)"
        urlComponents[5] = "lon=\(coordinate.longitude)"
        urlComponents[6] = "radius=\(radius)"
        urlComponents[7] = "per_page=\(photosPerPage)"
        urlComponents[8] = "page=\(page)"
        let urlString = "&".join(urlComponents)
        println("urlStiring = \(urlString)\n")
        return urlString
    }
    
    class func buildImageURLWith(photo : [String : AnyObject]) -> String {
        var imageURLComponents = [
            "https://farm",
            "{farm-id}",
            ".staticflickr.com/",
            "{server-id}",
            "/",
            "{id}",
            "_",
            "{secret}",
            "_z.jpg"]
        imageURLComponents[1] = String(photo["farm"] as! Int)
        imageURLComponents[3] = photo["server"] as! String
        imageURLComponents[5] = photo["id"] as! String
        imageURLComponents[7] = photo["secret"] as! String
        let imageURLString = "".join(imageURLComponents)
        println("imageURLStiring = \(imageURLString)\n")
        return imageURLString
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