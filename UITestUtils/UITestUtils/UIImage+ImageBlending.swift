//
//  UIImage+ImageBlending.swift
//  UITestUtils
//
//  Created by Chun-Fu Chen on 6/28/16.
//  Copyright © 2016 Zabiyaka. All rights reserved.
//

import Foundation

extension UIImage {

  static func imageBlending(imageA: UIImage, _ imageB: UIImage, _ ratioOfImageA: Float)
    -> UIImage? {
      let size = imageA.size
      UIGraphicsBeginImageContext(size)
      let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)

      imageA.drawInRect(areaSize)
      imageB.drawInRect(areaSize, blendMode: CGBlendMode.Normal,
                        alpha: CGFloat(ratioOfImageA))
      let resultImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return resultImage
  }
}