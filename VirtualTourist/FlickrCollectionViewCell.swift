//
//  FlickrCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Umar Qattan on 7/16/15.
//  Copyright (c) 2015 Umar Qattan. All rights reserved.
//

import Foundation
import UIKit

class FlickrCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet weak var flickrImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    /**
        MARK: cancels the cells download task by cancelling
              the NSURLSessionTask
    **/
    var urlTask: NSURLSessionTask? {
        
        didSet {
            if let task = oldValue {
                task.cancel()
            }
        }
    }
    
}