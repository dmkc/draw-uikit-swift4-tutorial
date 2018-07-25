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
    func fromTouch(touch: UITouch, timestamp: Date, view: UIView, previousPoint: SPoint?) {
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

extension SDocument {
    func toUIImage(frame: CGRect) -> UIImage {
        let blank = CALayer()
        blank.frame = frame
        var image = blank.renderIntoUIImage()
        
        for c in scurves?.allObjects as! [SCurve] {
            let curvePath = c.toUIBezierPath()
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = frame
            shapeLayer.lineWidth = 2.0
            shapeLayer.strokeColor = UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0).cgColor
            shapeLayer.fillColor = UIColor.init(white: 0.0, alpha: 0.0).cgColor
            shapeLayer.lineJoin = kCALineJoinRound
            shapeLayer.lineCap = kCALineCapRound
            
            shapeLayer.path = curvePath
            
            image = image.overlayWith(image: shapeLayer.renderIntoUIImage(), posX: 0.0, posY: 0.0)
        }
        return image
    }
}

extension SCurve {
    func toUIBezierPath() -> CGPath {
        let path = UIBezierPath()
        let points = spoints?.sorted {
            ($0 as! SPoint).timestamp?.compare(($1 as! SPoint).timestamp!) == ComparisonResult.orderedDescending
        } as! [SPoint]
        let cgPoints = points.map({ (p: SPoint) -> CGPoint in
            return CGPoint.init(x: p.x , y: p.y)
        })
        
        path.lineJoinStyle = .round
        
        for (index,point) in cgPoints.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path.cgPath
    }
}
