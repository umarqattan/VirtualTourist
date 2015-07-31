//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/16/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

let NEW_COLLECTION = "New Collection"
let REMOVE_SELECTED_PICTURES = "Remove Selected Pictures"

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    var pin : VirtualTouristPin!
    var cache = Cache()
    
    var allPhotosLoaded = true
    var noPhotosLoaded = true
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
      
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "urlPath", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    lazy var sharedContext : NSManagedObjectContext = {
    
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    
    }()
    
    func fetch() {
        var error = NSErrorPointer()
        fetchedResultsController.performFetch(error)
        if error != nil {
            println("Could not perform fetch due to \(error)")
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.flickrCollectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var error : NSError? = nil
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(&error)
        fetch()
        
        
        setDelegates()
        zoomIntoPinRegionOnStaticMapView(pin)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeNotifications()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        addNotifications()
        newCollectionButton.title = "Loading"
        checkIfImagesLoaded()
        
        if noPhotosLoaded {
            dispatch_async(dispatch_get_main_queue()) {
                self.newCollectionButton.title = "No Photos Found"
                self.newCollectionButton.enabled = false
            }
        }
        if allPhotosLoaded {
            dispatch_async(dispatch_get_main_queue()) {
                self.newCollectionButton.title = "New Collection"
                self.newCollectionButton.enabled = true
            }
        }
    }
    
    func checkIfImagesLoaded() {
        for image in pin.images {
            if image.status != .Done {
                allPhotosLoaded = false
            } else {
                noPhotosLoaded = false
            }
        }
    }
    
    /**
        MARK: when the user taps "New Collection" button on
              the UIToolbar, the Photo class grabs a new set of
              images with which to reload the flickrCollectionView.
    **/
    
    @IBAction func newCollection(sender: AnyObject) {
        newCollectionButton.enabled = false
        newCollectionButton.title = "New Collection"
        println("Pressed New Collection")
        pin.deletePhotos()
        pin.getPhotos(reload: true) { pages in
            println("Loading...")
            dispatch_async(dispatch_get_main_queue()) {
                self.newCollectionButton.title = "Loading..."
            }
            if pages > 0 {
                println("There are \(pages) pages")
                self.fetch()
                println("Getting more images")
                CoreDataStackManager.sharedInstance().saveContext()
                dispatch_async(dispatch_get_main_queue()) {
                    self.flickrCollectionView.reloadData()
                    self.newCollection(sender)
                }
            } else {
                println("Could not get photos")
            }
        }
    }
    
    func addNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "photosFinishedLoading:" as Selector,
            name: Flickr.Notifications.PhotosLoadedForPin,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "photoFinishedLoading:" as Selector,
            name: Flickr.Notifications.PhotosLoadedForPin,
            object: nil)
    }
    
    func removeNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Flickr.Notifications.PhotoLoaded,
            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Flickr.Notifications.PhotosLoadedForPin,
            object: nil)
    }
    
    /**
        MARK: when all the photos in the flickrCollectionViewController
              finish loading, the button to refresh the collectionView
              with new photos is enabled.
    **/
    
    func photosFinishedLoading(notification : NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.newCollectionButton.title = "New Collection"
            self.newCollectionButton.enabled = true
            println("PhotosFinishedLoading")
        }
    }
    
    /**
        MARK: for each cell in the flickrCollectionViewController,
              a photo is loaded. After a photo has finished loading,
              it is displayed in its respective flickrCollectionViewCell
              and its activityIndicator stops animating.
    **/
    func photoFinishedLoading(photo: Photo) {
        dispatch_async(dispatch_get_main_queue()) {
            self.flickrCollectionView.reloadData()
            println("PhotoFinishedLoading")
        }
    }
    
    /**
        MARK: UICollectionViewDelegate methods to return the number
              of sections in the collection, the number of items in
              each section, the cell for each indexPath (including
              the photo and acitivtyIndicator, depending on whether
              it has loaded or not), and whether the cell has been 
              selected for deletion.
    
    **/
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCollectionViewCell", forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.flickrImageView.image = UIImage(named: "Error-32")
        cell.activityIndicator.startAnimating()
        
        if let image = cache.imageForIdentifier(photo.filePath) {
            cell.activityIndicator.stopAnimating()
            cell.flickrImageView.image = image
        } else if photo.status == .Idle {
            configureCell(cell, photo: photo)
        }
        
        return cell
    }
    
    func configureCell(cell: FlickrCollectionViewCell, photo: Photo) {
        let task = cache.downloadImage(photo.filePath) { imageData, error in
            if imageData != nil {
                let image = UIImage(data: imageData!)
                photo.saveImage(image!)
                cell.flickrImageView.image = image
                cell.activityIndicator.stopAnimating()
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    println("error downloading image \(error)")
                    photo.deleteImage()
                }
            }
        }
        
        cell.urlTask = task
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.status == .Done {
            photo.deleteImage()
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 110.0, height: 110.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Delete :
                flickrCollectionView.deleteItemsAtIndexPaths([indexPath!])
            case .Insert :
                return
            default :
                return
        }
    }
    
    func zoomIntoPinRegionOnStaticMapView(pin : VirtualTouristPin) {
        var span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        var region = MKCoordinateRegion(center: pin.coordinate, span: span)
    
        mapView.addAnnotation(pin)
        mapView.setRegion(region, animated: true)
        mapView.regionThatFits(region)
        mapView.userInteractionEnabled = false
    }
    
    /**
        MARK: method to set delegates of both the mapView
              and the flickrCollectionView to the PhotoAlbum-
              ViewController, a.k.a. self
        SOLUTION: http://stackoverflow.com/questions/14866812/trying-to-center-map-on-pin-mkmapview
    **/
    
    func setDelegates() {
        mapView.delegate = self
        flickrCollectionView.delegate = self
        flickrCollectionView.dataSource = self
    }
    
}

