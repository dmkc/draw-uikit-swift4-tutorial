//
//  ModelExtensions.swift
//  DrawPad
//
//  Created by Dmytro Kichenko on 2018-07-08.
//  Copyright © 2018 Ray Wenderlich. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension SPoint {
    convenience init(touch: UITouch, timestamp: Date, view: UIView, previousPoint: SPoint?) {
        self.init()
        let location = touch.location(in: view)
        
        self.x = Double(location.x)
        self.y = Double(location.y)
        self.azimuth = Double(touch.azimuthAngle(in: view))
        self.altitude = Double(touch.altitudeAngle)
        self.timestamp = timestamp
        if previousPoint != nil {
            self.velocity = SPoint.calculateVelocity(p1: self, p2: previousPoint!)
        } else {
            self.velocity = 0.0
        }
    }
    
    static func calculateVelocity(p1: SPoint, p2: SPoint) -> Double {
        let t = p1.timestamp?.timeIntervalSince(p2.timestamp!)
        let timestampDiff = abs(t!)
        let x_velocity = abs(p1.x - p2.x) / timestampDiff
        let y_velocity = abs(p1.y - p2.y) / timestampDiff
        
        return sqrt(pow(x_velocity, 2.0) + pow(y_velocity, 2.0))
    }
}
