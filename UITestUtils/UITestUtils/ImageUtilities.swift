//
//  ImageUtilities.swift
//  CNN-iOS
//
//  Created by Chun-Fu Chen on 5/17/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import UIKit

class ImageUtilities {

  static func loadImage(imageName: String) -> UIImage? {
    let imageNameArray = imageName.characters.split {$0 == "."}.map(String.init)
    var testImage: UIImage? = nil
    if let path = NSBundle.mainBundle().pathForResource(imageNameArray[0],
                                                        ofType: imageNameArray[1]) {
      testImage = UIImage(contentsOfFile: path)
    }
    return testImage
  }

  static func resizeImage(image: UIImage, scaledToSize: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(scaledToSize, false, 1.0);
    image.drawInRect(CGRectMake(0, 0, scaledToSize.width, scaledToSize.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
  }

  static func maskFirst8bitsFrom32bits(input: UInt32) -> UInt8 {
    return (UInt8)(input & 0xFF)
  }

  static func maskSecond8bitsFrom32bits(input: UInt32) -> UInt8 {
    return (UInt8)((input >> 8) & 0xFF)
  }

  static func maskThird8bitsFrom32bits(input: UInt32) -> UInt8 {
    return (UInt8)((input >> 16) & 0xFF)
  }

  static func maskForth8bitsFrom32bits(input: UInt32) -> UInt8 {
    return (UInt8)((input >> 24) & 0xFF)
  }

  static func create32bPixelFromRGBA(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> UInt32 {
    let red32: UInt32 = UInt32(red)
    let green32: UInt32 = UInt32(green) << 8
    let blue32: UInt32 = UInt32(blue) << 16
    let alpha32: UInt32 = UInt32(alpha) << 24
    let pixel = red32 + green32 + blue32 + alpha32
    return pixel
//      UInt32(red + (green << 8) + (blue << 16) + (alpha << 24))
  }

  static func extractRGBfromRGBA(input: UInt32) -> (red: UInt8, green: UInt8, blue: UInt8) {
    let red = self.maskFirst8bitsFrom32bits(input)
    let green = self.maskSecond8bitsFrom32bits(input)
    let blue = self.maskThird8bitsFrom32bits(input)
    return (red, green, blue)
  }

  static func extractRGBA(input: UInt32) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    let red = self.maskFirst8bitsFrom32bits(input)
    let green = self.maskSecond8bitsFrom32bits(input)
    let blue = self.maskThird8bitsFrom32bits(input)
    let alpha = self.maskForth8bitsFrom32bits(input)
    return (red, green, blue, alpha)
  }

  static func getBtyesBuffer(inputImage: UIImage) -> [UInt8] {

    let inputCGImage = inputImage.CGImage
    let inputWidth = CGImageGetWidth(inputCGImage)
    let inputHeight = CGImageGetHeight(inputCGImage)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4 //CGImageGetBitsPerPixel(inputCGImage) / 8
    let bitsPerComponent = 8 //CGImageGetBitsPerComponent(inputCGImage)
    //    let inputBytesPerRow = CGImageGetBytesPerRow(inputCGImage)
    let inputBytesPerRow = bytesPerPixel * inputWidth;
    let alphaInfo = CGImageAlphaInfo.PremultipliedLast.rawValue //CGImageGetAlphaInfo(inputCGImage)
    let bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue //CGImageGetBitmapInfo(inputCGImage)

    var inputPixels = Array<UInt32>(count: inputWidth * inputHeight * sizeof(UInt32),
                                    repeatedValue: 0)
    //    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue)
    let context = CGBitmapContextCreate(UnsafeMutablePointer<Void>(inputPixels), inputWidth,
                                        inputHeight, bitsPerComponent, inputBytesPerRow,
                                        colorSpace, alphaInfo | bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(inputWidth), CGFloat(inputHeight)),
                       inputCGImage);

    var bytesArray = Array<UInt8>(count: inputWidth * inputHeight * 4, repeatedValue: 0)
    for j in 0..<inputWidth {
      for i in 0..<inputHeight {
        let pixel = inputPixels[(j * inputWidth) + i]
        let color = self.extractRGBA(pixel)
        bytesArray[j * inputWidth + i] = color.red
        bytesArray[1 * inputWidth * inputHeight + j * inputWidth + i] = color.green
        bytesArray[2 * inputWidth * inputHeight + j * inputWidth + i] = color.blue
        bytesArray[3 * inputWidth * inputHeight + j * inputWidth + i] = color.alpha
      }
    }
    return bytesArray
  }

  static func getUInt32Buffer(inputImage: UIImage) -> [UInt32] {

    let inputCGImage = inputImage.CGImage
    let inputWidth = CGImageGetWidth(inputCGImage)
    let inputHeight = CGImageGetHeight(inputCGImage)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4 //CGImageGetBitsPerPixel(inputCGImage) / 8
    let bitsPerComponent = 8 //CGImageGetBitsPerComponent(inputCGImage)
    //    let inputBytesPerRow = CGImageGetBytesPerRow(inputCGImage)
    let inputBytesPerRow = bytesPerPixel * inputWidth;
    let alphaInfo = CGImageAlphaInfo.PremultipliedLast.rawValue //CGImageGetAlphaInfo(inputCGImage)
    let bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue //CGImageGetBitmapInfo(inputCGImage)

    let inputPixels = Array<UInt32>(count: inputWidth * inputHeight * sizeof(UInt32),
                                    repeatedValue: 0)
    //    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue)
    let context = CGBitmapContextCreate(UnsafeMutablePointer<Void>(inputPixels), inputWidth,
                                        inputHeight, bitsPerComponent, inputBytesPerRow,
                                        colorSpace, alphaInfo | bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(inputWidth), CGFloat(inputHeight)),
                       inputCGImage);
    return inputPixels
  }

  static func imageDifference(imageA: UIImage, _ imageB: UIImage) -> UIImage? {
//    let imageARawData = ImageUtilities.getBtyesBuffer(imageA)
//    let imageBRawData = ImageUtilities.getBtyesBuffer(imageB)

    let imageARawData1 = ImageUtilities.getUInt32Buffer(imageA)
    let imageBRawData1 = ImageUtilities.getUInt32Buffer(imageB)

//    var imageDiff = [UInt8]()
//
//    for (pixelA, pixelB) in zip(imageARawData, imageBRawData) {
//      let pixelDiff = (pixelA != pixelB) ? 255 : 0
////      let pixelDiff = (pixelA > pixelB) ? (pixelA - pixelB) : (pixelB - pixelA)
//      imageDiff.append(UInt8(pixelDiff))
//    }

    let cgImageA = imageA.CGImage!
    let imageWidth = CGImageGetWidth(cgImageA)
    let imageHeight = CGImageGetHeight(cgImageA)
    let bitsPerComponent = CGImageGetBitsPerComponent(cgImageA)
    let bitsPerPixel = CGImageGetBitsPerPixel(cgImageA)
    let bytesPerRow = CGImageGetBytesPerRow(cgImageA)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageGetBitmapInfo(cgImageA)
    let RGBAWhite: UInt32  = 0xFFFFFFFF
    let RGBABlack: UInt32 = 0xFF000000
    let heightOfStatusBar = 40
    
    var imageDiffTemp = Array<UInt32>(count: imageWidth * imageHeight, repeatedValue: RGBABlack)

    for j in heightOfStatusBar..<imageHeight {
      for i in 0..<imageWidth {
        if imageARawData1[j * imageWidth + i] != imageBRawData1[j * imageWidth + i] {
          imageDiffTemp[j * imageWidth + i] = RGBAWhite
        } else {
          imageDiffTemp[j * imageWidth + i] = RGBABlack
        }
//        let diff = Int(imageDiff[j * imageWidth + i]) +
//                   Int(imageDiff[imageWidth * imageHeight + j * imageWidth + i]) +
//                   Int(imageDiff[2 * imageWidth * imageHeight + j * imageWidth + i])
//        if diff > 0 {
//          imageDiffTemp[j * imageWidth + i] = create32bPixelFromRGBA(UInt8(255), green: UInt8(255), blue: UInt8(255), alpha: UInt8(255))
//        } else {
//          imageDiffTemp[j * imageWidth + i] = create32bPixelFromRGBA(UInt8(0), green: UInt8(0), blue: UInt8(0), alpha: UInt8(255))
//        }
//        imageDiffTemp[j * imageWidth + i] =
//          create32bPixelFromRGBA(imageDiff[j * imageWidth + i],
//                                 green: imageDiff[imageWidth * imageHeight + j * imageWidth + i],
//                                 blue: imageDiff[2 * imageWidth * imageHeight + j * imageWidth + i],
//                                 alpha: imageDiff[3 * imageWidth * imageHeight + j * imageWidth + i])
      }
    }

    let cgProviderImageDiff = CGDataProviderCreateWithData(nil, imageDiffTemp, imageDiffTemp.count * bitsPerPixel / 8, nil)
    let cgImageDiff = CGImageCreate(imageWidth, imageHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, cgProviderImageDiff, nil, false, CGColorRenderingIntent.RenderingIntentDefault)

    let returnImage = UIImage(CGImage: cgImageDiff!)
    return returnImage

  }
}
