//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/16/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

let REUSEID = "reuseID"
let ADD = "Add"
let REMOVE = "Remove"
let EDIT = "Edit"
let DONE = "Done"
let TOUR = "Tour!"
let TAP_A_PIN = "Tap a Pin!"
let ON = "ON"
let OFF = "OFF"

class TravelLocationsMapViewController : UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var instructionView: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var tourButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var longPressGestureRecognizerToAdd : UILongPressGestureRecognizer!
    var mapRegion : MKCoordinateRegion!
    
    lazy var sharedContext : NSManagedObjectContext = {
       
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        
    }()
    
    func fetchAllVirtualTouristPins() -> [VirtualTouristPin] {
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "VirtualTouristPin")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        if error != nil {
            println("Could not execute fetch request due to: \(error)")
        }
        return results as! [VirtualTouristPin]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGestureRecognizers()
        setDelegates()
        configureMapView()
        configureTourButton()
        configureLoadingViews()
        
        let pins = fetchAllVirtualTouristPins()
        if pins.isEmpty {
            return
        } else {
            mapView.addAnnotations(pins)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTourButton()
        configureInstructionView(TOUR)
        configureLoadingViews()
        gestureRecognizerTo()
    }
    
    /**
        MARK: configure both instructionView and instructionLabel
              to change color and text depending on the editButton's
              title and the number of pins on the mapView.
    **/
    
    func configureInstructionView(option : String) {
        switch option {
            case ADD:
                UIView.animateWithDuration(0.3, animations: {
                    self.instructionView.backgroundColor = UIColor(red: 51.0/255.0, green: 147.0/255.0, blue: 210.0/255.0, alpha: 1.0)
                    self.instructionLabel.text = "Press to Drop Pin"
                })
            case REMOVE:
                UIView.animateWithDuration(0.3, animations: {
                    if self.fetchAllVirtualTouristPins().count > 0 {
                        self.instructionView.backgroundColor = UIColor.redColor()
                        self.instructionLabel.text = "Press Pin to Remove"
                    } else {
                        self.instructionView.backgroundColor = UIColor(red: 25.0/255.0, green: 224.0/255.0, blue: 20.0/255.0, alpha: 1.0)
                        self.instructionLabel.text = "The Map Is Empty"
                    }
                })
            case TOUR:
                UIView.animateWithDuration(0.3, animations: {
                    self.instructionView.backgroundColor = UIColor(red: 51.0/255.0, green: 147.0/255.0, blue: 210.0/255.0, alpha: 1.0)
                    self.instructionLabel.text = "Press to Drop Pin"
                })
            case TAP_A_PIN:
                UIView.animateWithDuration(0.3, animations: {
                    self.instructionView.backgroundColor = UIColor(red: 0.0/255.0, green: 99.0/255.0, blue: 220.0/255.0, alpha: 1.0)
                    self.instructionLabel.text = "Tap a Pin to Explore Flickr!"
                })
            default:
                return
        }
    }
    
    func configureTourButton() {
        if fetchAllVirtualTouristPins().count == 0 {
            tourButton.enabled = false
        } else {
            tourButton.enabled = true
            tourButton.title = "Tour!"
        }
    }
    
    func configureLoadingViews() {
        
        activityIndicator.hidden = true
        activityIndicator.stopAnimating()
    }
    
    func toggleTourButton() {
        if tourButton.title == TAP_A_PIN {
            configureInstructionView(TAP_A_PIN)
            editButton.enabled = false
        }
    }
    /**
        MARK: set the mapView delegate to the Travel-
              LocationsMapViewController, a.k.a. self.
    **/
    
    func setDelegates() {
        mapView.delegate = self
    }
    
    /**
        MARK: method to initialize the gestureRecognizers
              and add them to the mapView
    **/
    
    func setGestureRecognizers() {
        gestureRecognizerTo()
        longPressGestureRecognizerToAdd.enabled = true
    }
    
    @IBAction func editButtonAction(sender: UIBarButtonItem) {
        if sender.isEqual(editButton) {
            if editButton.title == EDIT {
                editButton.title = DONE
                longPressGestureRecognizerToAdd.enabled = false
                configureInstructionView(REMOVE)
                tourButton.title = TOUR
            } else if editButton.title == DONE {
                editButton.title = EDIT
                longPressGestureRecognizerToAdd.enabled = true
                configureInstructionView(ADD)
            }
        }
    }
    
    @IBAction func tourFlickrPhotos(sender: UIBarButtonItem) {
        if sender.isEqual(tourButton) {
            if tourButton.title == TOUR {
                tourButton.title = TAP_A_PIN
                configureInstructionView(TAP_A_PIN)
                longPressGestureRecognizerToAdd.enabled = false
            } else if tourButton.title == TAP_A_PIN {
                tourButton.title = TOUR
                configureInstructionView(TOUR)
                longPressGestureRecognizerToAdd.enabled = true
            }
        }
    }
    /**
        MARK: use pin, add info to it (lat/long), and
              animate its drop onto the mapView.
    **/
    
    func dropAPin(gestureRecognizer : UIGestureRecognizer) {
        
        let viewLocation = gestureRecognizer.locationInView(mapView)
        let coordinate = mapView.convertPoint(viewLocation, toCoordinateFromView: mapView)
        
        if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            let dictionary = ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
            let pin = VirtualTouristPin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            
            mapView.addAnnotation(pin)
            pin.getPhotos() { success in
                println("Downloaded")
            }
            configureTourButton()
        }
    }
    
    func gestureRecognizerTo() {
        longPressGestureRecognizerToAdd = UILongPressGestureRecognizer(target: self, action: Selector("dropAPin:"))
        longPressGestureRecognizerToAdd.minimumPressDuration = 0.5
        longPressGestureRecognizerToAdd.delegate = self
        mapView.addGestureRecognizer(longPressGestureRecognizerToAdd)
    }

    /**
        MARK: MKMapViewDelegate methods
    
    
        MARK: method that lets the delegate know when a pin has been
              selected. If the tourButton's title is "Tap a Pin!",
              then it enables the user to tap a pin to see the Flickr
              photos in the PhotoAlbumViewController. If the tourButton's
              title is "Tour" and the editButton's title is "Done", then
              remove the view (MKAnnotation) from the self.mapView and
              delete the NSManagedObject (VirtualTouristPin) from the 
              sharedContext.
    **/
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if tourButton.title == TAP_A_PIN {
            
            /**
                NOTE: implement method to load photos based 
                      on the MKAnnotationView's coordinate
            **/
            
            activityIndicator.startAnimating()
            
            UIView.animateWithDuration(0.3, animations: {
                self.instructionLabel.text = ""
            })
            
            mapView.deselectAnnotation(view.annotation, animated: true)
            let photoAlbumViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            let pin = view.annotation as! VirtualTouristPin
            photoAlbumViewController.pin = pin
            mapView.removeGestureRecognizer(longPressGestureRecognizerToAdd)
            navigationController?.pushViewController(photoAlbumViewController, animated: true)
            
        } else if tourButton.title == TOUR && editButton.title == DONE {
            
            /**
                PROBLEM: This was a pain because lldb kept saying that it couldn't
                         traverse the NSManagedObject array (NSArray) as a swift
                         array, so I had to cast the self.mapView.annotations's
                         [MKAnnotation] array as a [VirtualTouristPin] array, then
                         assign the result to a designated and newly initialized
                         [VirtualTouristPin] array. Works like a charm!
                SOLUTION: http://stackoverflow.com/questions/25484554/fatal-error-nsarray-element-failed-to-match-the-swift-array-element-type
            **/
            var pins = [VirtualTouristPin]()
            pins = self.mapView.annotations as! [VirtualTouristPin]
            for pin in pins {
                if (pin.coordinate.latitude == view.annotation.coordinate.latitude && pin.coordinate.longitude == view.annotation.coordinate.longitude) {
                    self.mapView.removeAnnotation(view.annotation)
                    sharedContext.deleteObject(pin)
                    configureInstructionView(REMOVE)
                    break
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    /**
        MARK: The following methods help archive/unarchive the mapView's
              region based on where on the mapView the user has zoomed 
              into before exiting/terminating the application. The region
              will be saved in the application's .DocumentDirectory in a
              UserDomainMask with a name called "saveTheMap"
    **/
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion(mapView.region)
    }

    /**
        MARK: PROBLEM:  I needed to find a way to animate the drop of a pin
                        onto the mapView, but every time I would remove the
                        pin, I would run into an error. The error said that
                        the mapView delegate could not find an MKPinAnnotation-
                        View to reuse.
              SOLUTION: http://stackoverflow.com/questions/24523702/stuck-on-using-mkpinannotationview-within-swift-and-mapkit
    **/

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
            
            if annotation is MKUserLocation {
                //return nil so map view draws "blue dot" for standard user location
                return nil
            }
            
            let reuseId = "VirtualTouristPin"
            
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.canShowCallout = false
                pinView!.animatesDrop = true
                pinView!.pinColor = MKPinAnnotationColor.Purple
            }
            else {
                pinView!.annotation = annotation
            }
            
            return pinView
    }
    
    var filePath : String {
        let urlPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return urlPath.URLByAppendingPathComponent("saveTheMap").path!
    }
    
    func configureMapView() {
        if let configuredMapRegion = loadMapRegion() {
            mapView.region = configuredMapRegion
        }
    }
    
    func saveMapRegion(region : MKCoordinateRegion) {
        let dictionary = [
            "CenterLatitude" : region.center.latitude,
            "CenterLongitude" : region.center.longitude,
            "SpanLatitudeDelta" : region.span.latitudeDelta,
            "SpanLongitudeDelta" : region.span.longitudeDelta
        ]
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func loadMapRegion() -> MKCoordinateRegion? {
        if let dictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            let centerLatitude = dictionary["CenterLatitude"] as! CLLocationDegrees
            let centerLongitude = dictionary["CenterLongitude"] as! CLLocationDegrees
            let spanLatitudeDelta = dictionary["SpanLatitudeDelta"] as! CLLocationDegrees
            let spanLongitudeDelta = dictionary["SpanLongitudeDelta"] as! CLLocationDegrees
            
            let center = CLLocationCoordinate2DMake(centerLatitude, centerLongitude)
            let span = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
            
            return MKCoordinateRegionMake(center, span)
            
        } else {
            return nil
        }
    }

}
    
    
