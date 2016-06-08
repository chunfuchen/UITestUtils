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

  public func UIVerification(testImageName: String, _ referenceImagesFolder: String) {
    let start = NSDate()
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
    var testImage = UIImage(contentsOfFile: testImageName)
    // random pick one reference image to resize testImage
    let randRefImage = UIImage(contentsOfFile: imageList.first!)
    if randRefImage!.size != testImage!.size {
      testImage = UIImage.imageResize(testImage!, scaledToSize: randRefImage!.size)
    }

    let similiarityScores = ImageUtilities.imageRetrieve(testImage!, imageList: imageList)
    let ranking = Utilities.sortWithIndex(similiarityScores, ascending: true)
    let end = NSDate()
    let elapsedTime = end.timeIntervalSinceDate(start)
    NSLog("\(elapsedTime)")
    NSLog("\(ranking)")
    if ranking.first!.1 > 0.3 {
      return
    }
    let topRankImage = UIImage(contentsOfFile: imageList[ranking.first!.0])
    let imageDiffAll = ImageUtilities.imageComparison(testImage!, topRankImage!)
    let imageDiff = imageDiffAll.first!
    let imageDiffGray = imageDiffAll.last!

    var textSize = CGFloat(40)
    var textCenter = 375
    var textOffset = 10
    if topRankImage!.size.width == CGFloat(375) {
      textSize = CGFloat(20)
      textCenter /= 2
      textOffset /= 2
    }

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
    textLocation = CGRect(x: textCenter - textGray.characters.count * textOffset, y: 0, width: 1, height: 1)
    let textDiffGrayImage = UIImage.setupTextImage(textGray, imageSize: testImage!.size,
                                                   faceRect: textLocation, textSize: textSize)
    let textDiffGrayImageWithText = ImageUtilities.overlayTextImageOnImage(
      textDiffGrayImage!, imageDiffGray!)

    var imageArray = [UIImage]()
    imageArray.append(imageDiff!)
    imageArray.append(textDiffGrayImageWithText!)
    imageArray.append(topRankImageWithText!)
    imageArray.append(testImageWithText!)
    let imageConcat = ImageUtilities.imageConcatenation(imageArray)

    let imageConcatTemp = UIImagePNGRepresentation(imageConcat)
    let imageConcatFileName = testImageName + "_vs_" + imageShortList[ranking.first!.0] + "_Concat.png"
    if !imageConcatTemp!.writeToFile(imageConcatFileName, atomically: false) {
      XCTFail("Unable to save the screenshot: \(imageConcatFileName)")
    }
//    NSLog("Comparing image spends \(elapsedTime) seconds\n")
  }
}
