//
//  ImageUtilities.swift
//  CNN-iOS
//
//  Created by Chun-Fu Chen on 5/17/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import UIKit
import Accelerate
import Darwin
import CoreImage

struct Pixel {
  var value: UInt32
  var red: UInt8 {
    get { return UInt8(value & 0xFF) }
    set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
  }
  var green: UInt8 {
    get { return UInt8((value >> 8) & 0xFF) }
    set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
  }
  var blue: UInt8 {
    get { return UInt8((value >> 16) & 0xFF) }
    set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
  }
  var alpha: UInt8 {
    get { return UInt8((value >> 24) & 0xFF) }
    set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
  }
}

struct RGBA {
  var pixels: UnsafeMutableBufferPointer<Pixel>
  var width: Int
  var height: Int

  init?(image: UIImage) {
    guard let cgImage = image.CGImage else { return nil } // 1

    width = Int(image.size.width)
    height = Int(image.size.height)
    let bitsPerComponent = 8 // 2

    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let imageData = UnsafeMutablePointer<Pixel>.alloc(width * height)
    let colorSpace = CGColorSpaceCreateDeviceRGB() // 3

    var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
    bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
    guard let imageContext = CGBitmapContextCreate(imageData, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
    CGContextDrawImage(imageContext, CGRect(origin: CGPointZero, size: image.size), cgImage) // 4

    pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
  }

  func toUIImage() -> UIImage? {
    let bitsPerComponent = 8 // 1

    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB() // 2

    var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
    bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
    let imageContext = CGBitmapContextCreateWithData(pixels.baseAddress, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo, nil, nil)
    guard let cgImage = CGBitmapContextCreateImage(imageContext) else {return nil} // 3

    let image = UIImage(CGImage: cgImage)
    return image
  }
}

class ImageUtilities {

  static func resizeImage(image: UIImage, scaledToSize: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(scaledToSize, false, 1.0);
    image.drawInRect(CGRectMake(0, 0, scaledToSize.width, scaledToSize.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
  }

  static func getUInt32Buffer(inputImage: UIImage) -> [UInt32] {

    let inputCGImage = inputImage.CGImage
    let inputWidth = CGImageGetWidth(inputCGImage)
    let inputHeight = CGImageGetHeight(inputCGImage)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4 //CGImageGetBitsPerPixel(inputCGImage) / 8
    let bitsPerComponent = 8 //CGImageGetBitsPerComponent(inputCGImage)
    let inputBytesPerRow = bytesPerPixel * inputWidth;
    let alphaInfo = CGImageAlphaInfo.PremultipliedLast.rawValue //CGImageGetAlphaInfo(inputCGImage)
    var bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue
    bitmapInfo |= alphaInfo & CGBitmapInfo.AlphaInfoMask.rawValue


    let inputPixels = Array<UInt32>(count: inputWidth * inputHeight,
                                    repeatedValue: 0)
    let context = CGBitmapContextCreate(UnsafeMutablePointer<Void>(inputPixels), inputWidth,
                                        inputHeight, bitsPerComponent, inputBytesPerRow,
                                        colorSpace, bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(inputWidth), CGFloat(inputHeight)), inputCGImage);
    return inputPixels
  }

  static func getFloatBuffer(inputImage: UIImage) -> [Float] {
    let inputCGImage = inputImage.CGImage
    let inputWidth = CGImageGetWidth(inputCGImage)
    let inputHeight = CGImageGetHeight(inputCGImage)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4 //CGImageGetBitsPerPixel(inputCGImage) / 8
    let bitsPerComponent = 8 //CGImageGetBitsPerComponent(inputCGImage)
    let inputBytesPerRow = bytesPerPixel * inputWidth;
    let alphaInfo = CGImageAlphaInfo.PremultipliedLast.rawValue //CGImageGetAlphaInfo(inputCGImage)
    var bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue
    bitmapInfo |= alphaInfo & CGBitmapInfo.AlphaInfoMask.rawValue
    var inputPixels = UnsafeMutablePointer<Pixel>.alloc(inputWidth * inputHeight)
    let context = CGBitmapContextCreate(inputPixels, inputWidth,
                                        inputHeight, bitsPerComponent, inputBytesPerRow,
                                        colorSpace, bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(inputWidth), CGFloat(inputHeight)),
                       inputCGImage);
    var bytesArray = Array<Float>(count: inputWidth * inputHeight * 3, repeatedValue: 0)
    for j in 0..<inputWidth {
      for i in 0..<inputHeight {
        let pixel = inputPixels[(j * inputWidth) + i]
          bytesArray[j * inputWidth + i] = Float(pixel.red)
          bytesArray[1 * inputWidth * inputHeight + j * inputWidth + i] = Float(pixel.green)
          bytesArray[2 * inputWidth * inputHeight + j * inputWidth + i] = Float(pixel.blue)
      }
    }
    return bytesArray
  }

  static func frameDifference(imageA: [Float], _ imageB:[Float], _ imageWidth: Int,
                              _ imageHeight: Int, _ imageChannel: Int) -> Float {
    let imagePixel = imageWidth * imageHeight
    var diff: Float = 0.0
    let statusBarPixelOffset = 0//500 * imageWidth
    NSLog("\(statusBarPixelOffset)\t\(imagePixel)")
    for i in 0..<3 {
      let pixelStartOffset = i * imagePixel + statusBarPixelOffset
      let pixelEndOffset = (i + 1) * imagePixel
      let imageATemp = Array(imageA[pixelStartOffset..<pixelEndOffset])
      let imageBTemp = Array(imageB[pixelStartOffset..<pixelEndOffset])
      var imageDiffTemp = Array<Float>(count: pixelEndOffset - pixelStartOffset, repeatedValue: 0.0)
      var diffTemp: Float = 0.0
      for i in 0..<imageBTemp.count {
        diffTemp += fabs(imageATemp[i] - imageBTemp[i])
      }
      diff += diffTemp
    }
    return diff
  }

  static func similiarityMeasurement(imageA: [Float], _ imageB:[Float], _ imageWidth: Int,
                                     _ imageHeight: Int, _ imageChannel: Int) -> Float {
    return ImageUtilities.frameDifference(imageA, imageB, imageWidth, imageHeight, imageChannel)
  }

  static func similiarityMeasurement(imageA: UIImage, _ imageB:UIImage) -> Float {
    let rgbaImageA = RGBA(image: imageA)!
    let rgbaImageB = RGBA(image: imageB)!
    var diff: Float = 0.0
    for i in 0..<(rgbaImageA.height * rgbaImageA.width) {
      diff += fabs(Float(rgbaImageA.pixels[i].red) - Float(rgbaImageB.pixels[i].red))
      diff += fabs(Float(rgbaImageA.pixels[i].green) - Float(rgbaImageB.pixels[i].green))
      diff += fabs(Float(rgbaImageA.pixels[i].blue) - Float(rgbaImageB.pixels[i].blue))
    }
    diff /= Float(rgbaImageA.height * rgbaImageA.width * 3)
    return diff
  }

  static func imageRetrieve(testImage: UIImage, imageList: [String]) -> [Float] {
    var scores = [Float]()
    var testImageRawData = [Float]()
    var resizedTestImage = testImage
    var imageWidth = Int(resizedTestImage.size.width)
    var imageHeight = Int(resizedTestImage.size.height)
    for image in imageList {
      var refImage = UIImage(contentsOfFile: image)
      if refImage == nil {
        NSLog("\(image) is not an image.")
        scores.append(FLT_MAX)
        continue
      }
      if resizedTestImage.size != refImage!.size {
        resizedTestImage = ImageUtilities.resizeImage(testImage, scaledToSize: refImage!.size)
        imageWidth = Int(resizedTestImage.size.width)
        imageHeight = Int(resizedTestImage.size.height)
      }
      testImageRawData = ImageUtilities.getFloatBuffer(resizedTestImage)
      let refImageRawData = ImageUtilities.getFloatBuffer(refImage!)
      let diff = ImageUtilities.similiarityMeasurement(resizedTestImage, refImage!)
      scores.append(diff)
    }
    return scores
  }

  static func imageComparison(testImage: UIImage, _ refImage: UIImage) -> [UIImage?] {
    var resizedTestImage = testImage
    if testImage.size != refImage.size {
      resizedTestImage = ImageUtilities.resizeImage(testImage, scaledToSize: refImage.size)
    }
    let cgImageA = refImage.CGImage!
    let imageWidth = CGImageGetWidth(cgImageA)
    let imageHeight = CGImageGetHeight(cgImageA)
    let bitsPerComponent = CGImageGetBitsPerComponent(cgImageA)
    let bitsPerPixel = CGImageGetBitsPerPixel(cgImageA)
    let bytesPerRow = CGImageGetBytesPerRow(cgImageA)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageGetBitmapInfo(cgImageA)
    let RGBAWhite: UInt32  = 0xFFFFFFFF
    let RGBABlack: UInt32 = 0xFF000000
    var heightOfStatusBar = 40
    if imageWidth != 750 {
      heightOfStatusBar = 20
    }
    let imageARawData = ImageUtilities.getUInt32Buffer(resizedTestImage)
    let imageBRawData = ImageUtilities.getUInt32Buffer(refImage)

    var imageDiffTemp = Array<UInt32>(count: imageWidth * imageHeight, repeatedValue: RGBABlack)
    let rgbaTest = RGBA(image: testImage)!
    let rbgaRef = RGBA(image: refImage)!

    for j in 0..<imageHeight {
      for i in 0..<imageWidth {
        let testY: Float = (Float(rgbaTest.pixels[j * imageWidth + i].red) +
                    Float(rgbaTest.pixels[j * imageWidth + i].green) +
                    Float(rgbaTest.pixels[j * imageWidth + i].blue))/3
        let refY: Float =  (Float(rbgaRef.pixels[j * imageWidth + i].red) +
                    Float(rbgaRef.pixels[j * imageWidth + i].green) +
                    Float(rbgaRef.pixels[j * imageWidth + i].blue))/3

        let absDiffY: UInt8 = UInt8(fabs(testY - refY))

        if j < heightOfStatusBar {
          rgbaTest.pixels[j * imageWidth + i].red = 0
          rgbaTest.pixels[j * imageWidth + i].green = 0
          rgbaTest.pixels[j * imageWidth + i].blue = 0
        } else {
          rgbaTest.pixels[j * imageWidth + i].red = absDiffY
          rgbaTest.pixels[j * imageWidth + i].green = absDiffY
          rgbaTest.pixels[j * imageWidth + i].blue = absDiffY
        }
        if j < heightOfStatusBar {
          imageDiffTemp[j * imageWidth + i] = RGBABlack
        } else {
          if imageARawData[j * imageWidth + i] != imageBRawData[j * imageWidth + i] {
            imageDiffTemp[j * imageWidth + i] = RGBAWhite
          } else {
            imageDiffTemp[j * imageWidth + i] = RGBABlack
          }
        }
      }
    }
    let diffImage = rgbaTest.toUIImage()
    let cgProviderImageDiff = CGDataProviderCreateWithData(nil, imageDiffTemp, imageDiffTemp.count * bitsPerPixel / 8, nil)
    let cgImageDiff = CGImageCreate(imageWidth, imageHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, cgProviderImageDiff, nil, false, CGColorRenderingIntent.RenderingIntentDefault)
    
    let binaryImage = UIImage(CGImage: cgImageDiff!)
    return [binaryImage, diffImage]
  }

  static func imageConcatenation(images: [UIImage]) -> UIImage {
    let cgImageA = images.first!.CGImage!
    let imageWidth = CGImageGetWidth(cgImageA)
    let imageHeight = CGImageGetHeight(cgImageA)
    let bitsPerComponent = CGImageGetBitsPerComponent(cgImageA)
    let bitsPerPixel = CGImageGetBitsPerPixel(cgImageA)
    let bytesPerRow = CGImageGetBytesPerRow(cgImageA)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageGetBitmapInfo(cgImageA)

    var imageRawData = Array<Array<UInt32>>()
    for image in images {

      if Int(image.size.height) != imageHeight ||  Int(image.size.width) != imageWidth {
        let resizedImage = ImageUtilities.resizeImage(image, scaledToSize: images.first!.size)
        imageRawData.append(ImageUtilities.getUInt32Buffer(resizedImage))
      } else {
        imageRawData.append(ImageUtilities.getUInt32Buffer(image))
      }
    }
    var resultImageRawData = Array<UInt32>(count: imageWidth * imageHeight * images.count, repeatedValue: 0)
    for idx in 0..<imageRawData.count {
      let offset = idx * imageWidth
      for j in 0..<imageHeight {
        for i in 0..<imageWidth {
          resultImageRawData[j * imageWidth * images.count + i + offset] = imageRawData[idx][j * imageWidth + i]
        }
      }
    }

    let cgProviderImageConcat = CGDataProviderCreateWithData(nil, resultImageRawData, resultImageRawData.count * bitsPerPixel / 8, nil)
    let cgImageConcat = CGImageCreate(imageWidth * images.count, imageHeight, bitsPerComponent, bitsPerPixel, bytesPerRow * images.count, colorSpace, bitmapInfo, cgProviderImageConcat, nil, false, CGColorRenderingIntent.RenderingIntentDefault)

    let resultImage = UIImage(CGImage: cgImageConcat!)
    return resultImage
  }

  static func overlayTextImageOnImage(textImage: UIImage, _ image: UIImage) -> UIImage? {
    var size = image.size
    UIGraphicsBeginImageContext(size)
    let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let RGBAWhite: UInt32  = 0xFFFFFFFF
    let RGBABlack: UInt32 = 0xFF000000
    let rgbaImage = RGBA(image: image)!
    var heightOfStatusBar = 40
    if rgbaImage.width != 750 {
      heightOfStatusBar = 20
    }
    for j in 0..<rgbaImage.height {
      for i in 0..<rgbaImage.width {
        if j < heightOfStatusBar {
          rgbaImage.pixels[j * rgbaImage.width + i].value = RGBABlack
        }
      }
    }

    let imageNoStatusBar = rgbaImage.toUIImage()!
    imageNoStatusBar.drawInRect(areaSize)
    textImage.drawInRect(areaSize, blendMode: CGBlendMode.Normal, alpha: 1)
    var resultImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resultImage
  }
}

class Utilities {
  static func loadTextFileAsStringArray(textFileName: String) -> [String]? {
    var results:[String]? = nil
    do {
      let fileNames = try String(contentsOfFile: textFileName, encoding: NSUTF8StringEncoding)
      results = fileNames.characters.split {$0 == "\n"}.map(String.init)
    } catch {
      print("loadLabelFile: load file error, \(error)")
    }
    return results
  }

  static func sortWithIndex(inputArray: [Float], ascending: Bool = false) -> [(Int, Float)] {
    var arrayWithIndex = Dictionary<Int, Float> ()
    for i in 0..<inputArray.count {
      arrayWithIndex[i] = inputArray[i]
    }
    if ascending {
      let scoresTupleArray = arrayWithIndex.sort {
        $0.1 < $1.1
      }
      return scoresTupleArray
    } else {
      let scoresTupleArray = arrayWithIndex.sort {
        $0.1 > $1.1
      }
      return scoresTupleArray
    }

  }

}



