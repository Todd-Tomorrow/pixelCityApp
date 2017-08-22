//
//  DroppablePin.swift
//  pixelCity
//
//  Created by Todd Donnelly on 22/08/2017.
//  Copyright © 2017 Todd Donnelly. All rights reserved.
//


import UIKit
import MapKit
                    //inherets from
class DroppablePin: NSObject, MKAnnotation {
    //is a particular kind of variable needed for coordinate annotation
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier:String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String){
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
