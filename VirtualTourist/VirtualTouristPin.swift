//
//  VirtualTouristPin.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/18/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import MapKit
import CoreData


@objc(VirtualTouristPin)

class VirtualTouristPin : NSManagedObject, MKAnnotation {
    

    struct Keys {
        
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        
    }
    
    @NSManaged var latitude : NSNumber
    @NSManaged var longitude : NSNumber
    @NSManaged var page : Int
    @NSManaged var images : [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary : [String : AnyObject], context : NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("VirtualTouristPin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[VirtualTouristPin.Keys.Latitude] as! Double
        longitude = dictionary[VirtualTouristPin.Keys.Longitude] as! Double
        page = 1
    }
    
    lazy var sharedContext : NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    
    var coordinate:CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude as! Double, longitude: longitude as! Double)
        }
    }

    func getPhotos(reload: Bool = false, completionHandler: (pages: Int) -> Void) -> Void {
        if !reload {
            getImagesForPinFromFlickr() { pageCount in
                completionHandler(pages: pageCount)
                if pageCount > 0 {
                    var idlePhotos = self.images.count
                    for image in self.images {
                        image.status = .Loading
                        let task = Cache.sharedInstance().downloadImage(image.urlPath) { imageData, error in
                            idlePhotos--
                            if imageData == nil {
                                return
                            } else {
                                let anImage = UIImage(data: imageData!)
                                image.saveImage(anImage!)
                                if idlePhotos == 0 {
                                    println("idlePhotos = \(idlePhotos)")
                                    let notification = NSNotification(name: Flickr.Notifications.PhotosLoadedForPin, object: nil)
                                    NSNotificationCenter.defaultCenter().postNotification(notification)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            page++
        }
    }
    
    func getImagesForPinFromFlickr(completionHandler: (pages: Int) -> Void) {
        let url = NSURL(string: Flickr.buildURLWith(coordinate, radius: 3, photosPerPage: 15, and: page))!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                println("Could not complete searchFlickr request due to \(error)")
                completionHandler(pages: 0)
                return
            } else {
                var photoCount = 0
                var parsingError : NSError? = nil
                if let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &parsingError) as? NSDictionary {
                    if let photoDictionary = parsedResult["photos"] as? [String: AnyObject] {
                        if let photos = photoDictionary["photo"] as? [[String : AnyObject]] {
                            for photo in photos {
                                let filePath = photo["id"] as! String
                                let imageURL = Flickr.buildImageURLWith(photo)
                                let dict = [
                                    Photo.Keys.urlPath: imageURL,
                                    Photo.Keys.filePath: filePath
                                ]
                                let photo = Photo(dictionary: dict, context: self.sharedContext)
                                photo.pin = self
                                
                                var error:NSErrorPointer = NSErrorPointer()
                                self.sharedContext.save(error)
                                
                                if error != nil {
                                    println("Could not save the photo, \(photo) due to \(error)")
                                    break
                                }
                                photoCount++
                            }
                        }
                    }
                }
                completionHandler(pages: photoCount)
                println("pages = \(photoCount)")
            }
        }
        task.resume()
    }

    func deletePhotos() {
        for image in self.images {
            image.deleteImage()
        }
    }

}
