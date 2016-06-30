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

//struct defaultTextInStatusBarProperties {
//  let textSize = CGFloat(40)
//  var textCenter: Int = 0
//  var textOffset: Int = 0
//}

struct defaultImageSize {
  // UIDeviceOrientation.p
  static let iPhoneScreenshotWidth: CGFloat = CGFloat(1334)
  static let iPhoneScreenshotHeight: CGFloat = CGFloat(750)
  static let iPadScreenshotWidth: CGFloat = CGFloat(1536)
  static let iPadScreenshotHeight: CGFloat = CGFloat(2048)
}

struct UIVerificationConf {
  static let similiarityThreshold: Float = 0.3
  static let blendingRatio: Float = 0.25
}

extension XCTestCase {

  public func UIVerification(testImageName: String, _ referenceImagesFolder: String) {
//    let start = NSDate()
//    let widthAndHeight = screenResolution.characters.split {$0 == "x"}.map(String.init)
//    let screenWidth = Int(widthAndHeight[0])
//    let screenHeight = Int(widthAndHeight[1])
    var textCenter: Int
    var textOffset: Int
    var textSize: CGFloat = CGFloat(40/2)
    if deviceType == "pad" {
      if orientation.isPortrait {
        textCenter = 768/2
        textOffset = 20/2
      } else {
        textCenter = 1024/2
        textOffset = 25/2
      }
    } else {
      if orientation.isPortrait {
        textCenter = 375/2
        textOffset = 10/2
      } else {
        textCenter = 667/2
        textOffset = 20/2
      }
    }

    var imageList = [String]()
    let fileManager = NSFileManager.defaultManager()
    let enumerator = fileManager.enumeratorAtPath(referenceImagesFolder)
    var imageShortList = [String]()
    while let element = enumerator?.nextObject() as? String {
      if !element.hasSuffix(".png") {
        continue
      }
      if element.rangeOfString("Diff.png") == nil {
        imageList.append(referenceImagesFolder + element)
        imageShortList.append(element)
      }
    }
    var testImageTmp = UIImage(contentsOfFile: testImageName)
    var testImage: UIImage?
    if orientation.isPortrait {
      testImage = testImageTmp!
    } else {
      testImage = UIImage(CGImage: testImageTmp!.CGImage!, scale: CGFloat(1.0),
                              orientation: UIImageOrientation.Left)
    }

    // random pick one reference image to resize testImage
    let randRefImage = UIImage(contentsOfFile: imageList.first!)
//    if orientation.isPortrait {
      if randRefImage!.size.width / testImage!.size.width != randRefImage!.size.height / testImage!.size.height {
        XCTFail("Aspect ratio of reference image and screenshot is different.\nPlease rotate device and then performance verification again.")
      }
//    } else {
//      if randRefImage!.size.width / testImage.size.height != randRefImage!.size.height / testImage.size.width {
//        XCTFail("Aspect ratio of reference image and screenshot is different.\nPlease rotate device and then performance verification again.")
//      }
//    }

    if randRefImage!.size != testImage!.size {
      testImage = UIImage.imageResize(testImage!, scaledToSize: randRefImage!.size)
    }

    let similiarityScores = ImageUtilities.imageRetrieve(testImage!, imageList: imageList)
    let ranking = Utilities.sortWithIndex(similiarityScores, ascending: true)
//    let end = NSDate()
//    let elapsedTime = end.timeIntervalSinceDate(start)
//    NSLog("\(elapsedTime)")
//    NSLog("\(ranking)")
    if ranking.first!.1 > UIVerificationConf.similiarityThreshold {
      XCTFail("Retrieval fail, the smallest similiar value is \(ranking.first!.1)")
//      return
    }
    let topRankImage = UIImage(contentsOfFile: imageList[ranking.first!.0])
    let imageDiffAll = ImageUtilities.imageComparison(testImage!, topRankImage!)
    let imageDiff = imageDiffAll.first!
    let imageDiffGray = imageDiffAll.last!

//    var textSize = defaultTextInStatusBarProperties.textSize
//    var textCenter = defaultTextInStatusBarProperties.textCenter
//    var textOffset = defaultTextInStatusBarProperties.textOffset
//    if topRankImage!.size.width != defaultImageSize.iPhoneScreenshotWidth {
//      textSize /= 2
//      textCenter /= 2
//      textOffset /= 2
//    }

    let blendedImage = ImageUtilities.imageBlending(topRankImage!, testImage!,
                                                    UIVerificationConf.blendingRatio)

    let textRef = "Ground Truth"
    var textLocation = CGRect(x: textCenter - textRef.characters.count * textOffset, y: 0, width: 1, height: 1)
    let textRefImage = UIImage.setupTextImage(textRef, imageSize: topRankImage!.size,
                                              faceRect: textLocation, textSize: textSize)
    let topRankImageWithText = ImageUtilities.overlayTextImageOnImage(
      textRefImage!, topRankImage!)

    let textTest = "App Screenshot"
    textLocation = CGRect(x: textCenter - textTest.characters.count * textOffset, y: 0, width: 1, height: 1)
    let textTestImage = UIImage.setupTextImage(textTest, imageSize: testImage!.size,
                                               faceRect: textLocation, textSize: textSize)
    let testImageWithText = ImageUtilities.overlayTextImageOnImage(
      textTestImage!, testImage!)

    let textGray = "Intensity Difference"
    textLocation = CGRect(x: textCenter - textGray.characters.count * textOffset,
                          y: 0, width: 1, height: 1)
    let textDiffGrayImage = UIImage.setupTextImage(textGray, imageSize: testImage!.size,
                                                   faceRect: textLocation, textSize: textSize)
    let textDiffGrayImageWithText = ImageUtilities.overlayTextImageOnImage(
      textDiffGrayImage!, imageDiffGray!)

    let textBlend = "Blended Image"
    textLocation = CGRect(x: textCenter - textBlend.characters.count * textOffset,
                          y: 0, width: 1, height: 1)
    let textBlendImage = UIImage.setupTextImage(textBlend, imageSize: blendedImage!.size,
                                                faceRect: textLocation, textSize: textSize)
    let textBlendImageWithText = ImageUtilities.overlayTextImageOnImage(
      textBlendImage!, blendedImage!)

    var imageArray = [UIImage]()
    imageArray.append(imageDiff!)
    imageArray.append(textDiffGrayImageWithText!)
    imageArray.append(textBlendImageWithText!)
    imageArray.append(topRankImageWithText!)
    imageArray.append(testImageWithText!)
    let imageConcat = ImageUtilities.imageConcatenation(imageArray)

    let imageConcatTemp = UIImagePNGRepresentation(imageConcat)
    let imageConcatFileName = testImageName + "_vs_" + imageShortList[ranking.first!.0] + "_Concat.png"
    if !imageConcatTemp!.writeToFile(imageConcatFileName, atomically: false) {
      XCTFail("Unable to save the screenshot: \(imageConcatFileName)")
    }
    do {
      try fileManager.removeItemAtPath(testImageName)
    } catch {
      NSLog("delete temporary snapshot fail \(error)")
    }
//    NSLog("Comparing image spends \(elapsedTime) seconds\n")
  }
}
