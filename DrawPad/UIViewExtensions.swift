//
//  UIViewExtensions.swift
//  DrawPad
//
//  Created by Dmytro Kichenko on 2018-07-24.
//  Copyright © 2018 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit

extension UIView
{
    func renderIntoUIImage() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return image!
    }
}
