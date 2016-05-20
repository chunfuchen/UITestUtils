//
//  XCTestCase+ImageComparison.swift
//  UITestUtils
//
//  Created by Chun-Fu Chen on 5/19/16.
//  Copyright © 2016 Zabiyaka. All rights reserved.
//

import Foundation
import UIKit
import XCTest

extension XCTestCase {

  public func helloSIFT() {
    NSLog("hello SIFT")
  }

  public func UIVerificiation(testName: String) {
    let testImage = UIImage(contentsOfFile: testName)
    let testImageSize = testImage!.size
    NSLog("Test image size \(Int(testImageSize.width))x\(Int(testImageSize.height))")
    // Get reference image

    var refImage = UIImage(contentsOfFile: "/Users/cfchen/Temp/Screenshots/phone_750x1334_screenshot1_ori.png")

    var refImageSize = refImage!.size
    NSLog("Ref image size \(Int(refImageSize.width))x\(Int(refImageSize.height))")

    if testImageSize.width != refImageSize.width || testImageSize.height != refImageSize.height {
      refImage = ImageUtilities.resizeImage(refImage!, scaledToSize: testImageSize)
      NSLog("Size is different")
      refImageSize = refImage!.size
      if testImageSize.width == refImageSize.width && testImageSize.height == refImageSize.height {
        NSLog("Size is identical")
      }
//      UIImageWriteToSavedPhotosAlbum(resizedRefImage!, nil, nil, nil)
    } else {
//      UIImageWriteToSavedPhotosAlbum(refImage!, nil, nil, nil)
    }

    let imageDiff = ImageUtilities.imageDifference(testImage!, refImage!)
    UIImageWriteToSavedPhotosAlbum(testImage!, nil, nil, nil)
    UIImageWriteToSavedPhotosAlbum(refImage!, nil, nil, nil)
    UIImageWriteToSavedPhotosAlbum(imageDiff!, nil, nil, nil)
  }

}