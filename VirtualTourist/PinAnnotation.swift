//
//  PinAnnotation.swift
//  VirtualTourist
//
//  Created by Noha on 06.11.19.
//  Copyright © 2019 udacity. All rights reserved.
//

import Foundation
import MapKit

class PinAnnotation: MKPointAnnotation {
    let pin: Pin
    init(pin: Pin) {
        self.pin = pin
    }

    override var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: pin.latitude,
                                          longitude: pin.longitude)
        }
        set {}
    }
}
