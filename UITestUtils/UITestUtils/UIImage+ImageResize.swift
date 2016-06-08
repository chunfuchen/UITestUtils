//
//  UIImage+ImageResize.swift
//  DNNKit
//
//  Created by Chun-Fu Chen on 5/28/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

  static func imageResize(image: UIImage, scaledToSize: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(scaledToSize, false, 1.0)
    image.drawInRect(CGRect(origin: CGPointZero, size: scaledToSize))
    guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
    UIGraphicsEndImageContext()
    return newImage
  }

}