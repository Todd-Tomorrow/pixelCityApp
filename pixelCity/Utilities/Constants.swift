//
//  Constants.swift
//  pixelCity
//
//  Created by Todd Donnelly on 23/08/2017.
//  Copyright © 2017 Todd Donnelly. All rights reserved.
//

import Foundation

let API_KEY = "c6b9830e8a57ff31a33f89c95d1762b0"

func flickrURL(forApiKey: String, withAnnonation annotation: DroppablePin, addNumberOfPhotos number: Int) -> String{
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=10.0&radius_units=m&per_page=\(number)&format=json&nojsoncallback=1"
    
    return url
}
