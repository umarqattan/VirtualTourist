//
//  Photo.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/24/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import CoreData
import UIKit




@objc(Photo)

class Photo : NSManagedObject {
    
    struct Keys {
        static let filePath = "filePath"
        static let urlPath = "urlPath"
    }

    @NSManaged var pin : VirtualTouristPin?
    @NSManaged var filePath : String
    @NSManaged var urlPath : String
    var status: Flickr.Download.Status = .Idle
    var error : NSErrorPointer = NSErrorPointer()
    
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        if let image = Cache.sharedInstance().imageForIdentifier(filePath) {
            status = .Done
        }
    }
    
    init(dictionary : [String : AnyObject], context : NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        filePath = dictionary[Photo.Keys.filePath] as! String
        urlPath = dictionary[Photo.Keys.urlPath] as! String
    }
    
    func deleteImage() {
        Cache.sharedInstance().deleteImage(filePath)
        sharedContext.deleteObject(self)
        sharedContext.save(error)
        if error != nil {
            println("Could not delete the photo for path \(filePath) due to \(error)")
        }
    }
    
    /**
        MARK: As soon as the image is saved, a notification is posted to the
              default notification center with the identifier: Flickr.Notifications.
              PhotosLoaded.
    **/
    func saveImage(image: UIImage) {
        Cache.sharedInstance().saveImage(image, identifier: filePath)
        status = .Done
        println("image \(image) saved!")
        let notification = NSNotification(name: Flickr.Notifications.PhotoLoaded, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}