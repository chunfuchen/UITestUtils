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

  public func UIVerification(testImageName: String) {
    let start = NSDate()
    let referenceImagesFolder = realHomeDirectory + "/Temp/Screenshots/ReferenceImages/"
    var imageList = [String]()
    let fileManager = NSFileManager.defaultManager()
    let enumerator = fileManager.enumeratorAtPath(referenceImagesFolder)
    while let element = enumerator?.nextObject() as? String {
      if !element.hasSuffix(".png") {
        continue
      }
      if element.rangeOfString("Diff.png") == nil {
        imageList.append(referenceImagesFolder + element)
      }
    }
    let testImage = UIImage(contentsOfFile: testImageName)
    var similiarityScores = ImageUtilities.imageRetrieve(testImage!, imageList: imageList)
    let ranking = Utilities.sortWithIndex(similiarityScores, ascending: true)
//    NSLog("\(similiarityScores)")

    let topRankImage = UIImage(contentsOfFile: imageList[ranking[0].0])
    let imageDiff = ImageUtilities.imageComparison(testImage!, topRankImage!)

    let imageDiffTemp = UIImagePNGRepresentation(imageDiff!)
    let imageDiffFileName = imageList[ranking[0].0] + "_Diff.png"
//    let imageDiffFileName = realHomeDirectory + "/Temp/Screenshots/Diff.png"
    if !imageDiffTemp!.writeToFile(imageDiffFileName, atomically: false) {
      XCTFail("Unable to save the screenshot: \(imageDiffFileName)")
    }
    let end = NSDate()
    let elapsedTime = end.timeIntervalSinceDate(start)
//    NSLog("Comparing image spends \(elapsedTime) seconds\n")
  }

  public func UIVerification2(testName: String) {
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
