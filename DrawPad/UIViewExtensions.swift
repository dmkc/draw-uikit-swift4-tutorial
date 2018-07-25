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
        return self.layer.renderIntoUIImage()
    }
}
