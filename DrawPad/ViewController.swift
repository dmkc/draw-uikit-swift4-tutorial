//
//  ViewController.swift
//  DrawPad
//
//  Created by Jean-Pierre Distler on 13.11.14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    
    @IBOutlet weak var drawPointsSwitch: UISwitch!
    @IBOutlet weak var documentName: UITextField!
    
    var lastPoint = CGPoint.zero
    var lastTouch = UITouch()
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var brushWidth: CGFloat = 4.0
    var opacity: CGFloat = 1.0
    var swiped = false

    var smoothingEnabled = false
    
    var maxVelocity:Double = 0.0
    
    var predictedTouchColor = UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    var coalescedTouchColor = UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
    var touchColor = UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
    var pointColor = UIColor.init(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.1)
    
    // MARK: Models
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data init error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var pathSoFar = UIBezierPath()
    var curveSoFar: SCurve?
    var lastSPoint: SPoint?
    var currentDocument: SDocument?
    
    var pointsSoFar: [CGPoint]?
    var touchStart = Date.init()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //let entity = NSEntityDescription.entity(forEntityName: "SDocument2", in: container.viewContext)!
        //currentDocument = NSManagedObject(entity: entity, insertInto: container.viewContext) as? SDocument
        currentDocument = NSEntityDescription.insertNewObject(forEntityName: "SDocument", into: container.viewContext) as? SDocument
        
        currentDocument?.name = "Grisha"
        print("currentDocument initialized", currentDocument!)
        
        mainImageView.image = UIImage.init()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Draw paths
    // Return a UIBezierPath for a given set of CGPoints
    func getPathThroughPoints(points: [CGPoint]) -> UIBezierPath {
        var path = UIBezierPath()
        
        print("Drawing", points.count, "points. Smoothing enabled:", smoothingEnabled)
        if smoothingEnabled && points.count > 2 {
            if let p = UIBezierPath(hermiteInterpolatedPoints: points, closed: false) {
                path = p
            }
        } else {
            path = UIBezierPath()
            path.lineJoinStyle = .round
            
            path.move(to: points[0])
            for point in points {
                path.addLine(to: point)
            }
        }
        
        if drawPointsSwitch.isOn {
            drawPoints(points: points)
        }
        return path
    }
    
    func drawPath(path: UIBezierPath, color: UIColor) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = tempImageView.frame
        shapeLayer.lineWidth = 2.0
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = color.cgColor
        shapeLayer.lineJoin = kCALineJoinRound
        shapeLayer.lineCap = kCALineCapRound
        
        shapeLayer.path = path.cgPath
        tempImageView.layer.addSublayer(shapeLayer)
    }
    
    func drawPoints(points: [CGPoint]) {
        for p in points {
            drawPoint(point: p, color: pointColor.cgColor)
        }
    }
    
    func drawPoint(point: CGPoint, color: CGColor) {
        let dot = CAShapeLayer()
        dot.frame = mainImageView.frame
        
        dot.fillColor = color
    
        let startAngle = CGFloat(0.0)
        let endAngle = CGFloat(2.0 * .pi)
        let clockwise = true
        
        let circlePath = UIBezierPath(arcCenter: point,
                                      radius: CGFloat(3.0),
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: clockwise)
        
        dot.path = circlePath.cgPath
        mainImageView.layer.addSublayer(dot)
    }
    
    // MARK: - Touch handlers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touches began")
        pathSoFar = UIBezierPath()
        swiped = false
        touchStart = Date.init()
        
        if let touch = touches.first {
            lastPoint = touch.location(in: view)
            lastTouch = touch
            curveSoFar = NSEntityDescription.insertNewObject(forEntityName: "SCurve", into: container.viewContext) as? SCurve
            
            let point = NSEntityDescription.insertNewObject(
                forEntityName: "SPoint",
                into: container.viewContext) as? SPoint

            point?.fromTouch(
                touch: touch,
                timestamp: touchStart.addingTimeInterval(touch.timestamp),
                view: view,
                previousPoint: nil
            )
            lastSPoint = point
            
            curveSoFar!.spoints = NSSet.init(object: point!)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        
        if let touch = touches.first {
            // TODO: Use predicted touches
//            if let predictedTouches = event?.predictedTouches(for: touch) {
//                //drawLineThrough(touches: predictedTouches, color: predictedTouchColor)
//            }
            
            if let coalescedTouches = event?.coalescedTouches(for: touch) {
                
                var points = [lastPoint]
                points.append(contentsOf: coalescedTouches.map { (touch: UITouch) -> CGPoint in
                    return touch.location(in: view)
                })
                let path = getPathThroughPoints(points: points)
                
                pathSoFar.append(path)
                
                let point = NSEntityDescription.insertNewObject(
                    forEntityName: "SPoint",
                    into: container.viewContext) as? SPoint
                
                point?.fromTouch(
                    touch: touch,
                    timestamp: touchStart.addingTimeInterval(touch.timestamp),
                    view: view,
                    previousPoint: lastSPoint
                )
                
                curveSoFar!.addToSpoints(point!)
                
                drawPath(path: path, color: touchColor)
                print("Velocity", point!.velocity, "Max", maxVelocity)
                let velocity = point!.velocity
                
                if velocity > maxVelocity {
                    maxVelocity = velocity
                }

            }
    
            lastTouch = touch
            lastPoint = touch.location(in: view)
            
        }
        //drawBezierPath(touches: touches, event: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawPoint(point: lastPoint, color: touchColor.cgColor)
            
        }
        currentDocument!.addToScurves(curveSoFar!)

        mainImageView.image = mainImageView.image?.overlayWith(
            image: tempImageView.renderIntoUIImage(),
            posX: 0.0,
            posY: 0.0
        )
        tempImageView.layer.sublayers = [CALayer()]

    }

    
    // MARK: - Actions
    
    @IBAction func reset(_ sender: AnyObject) {
        mainImageView.image = nil
    }
    @IBAction func writeDocument(_ sender: AnyObject) {
        currentDocument?.name = documentName.text
        
        do {
            try container.viewContext.save()
        } catch {
            print("Couldn't save context")
        }
    }
    
    @IBAction func readDocument(_ sender: AnyObject) {
        
    }
    
    @IBAction func share(_ sender: AnyObject) {
    }
    
    @IBAction func pencilPressed(_ sender: AnyObject) {
    }
    
    @IBAction func toggleSmoothing(_ sender: UISwitch) {
        smoothingEnabled = sender.isOn 
    }
}

