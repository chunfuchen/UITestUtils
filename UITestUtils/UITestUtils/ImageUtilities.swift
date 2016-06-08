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
    let uint8Buffer = inputImage.getPlanarPixelArray()!
    let inputWidth = Int(inputImage.size.width)
    let inputHeight = Int(inputImage.size.height)
    var bytesArray = Array<Float>(count: inputWidth * inputHeight * 3, repeatedValue: 0)

    for j in 0..<inputWidth * inputHeight  {
      bytesArray[j] = Float(uint8Buffer[j])
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



  static func similiarityMeasurement(imageA: UIImage, _ imageB:UIImage)
    -> (Float, Float) {
    let imageAByteBuffer = imageA.getPlanarPixelArray()!
    let imageBByteBuffer = imageB.getPlanarPixelArray()!
    let imageWidth = Int(imageA.size.width)
    let imageHeight = Int(imageA.size.height)
    // color frame difference
    var diff: Float = 0.0
    for i in 0..<(imageHeight * imageWidth * 3) {
      diff += fabs(Float(imageAByteBuffer[i]) - Float(imageBByteBuffer[i]))
    }
    diff /= Float(imageHeight * imageWidth * 3)

    // edge map difference
    var imageAYBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
    var imageBYBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
    for i in 0..<imageWidth * imageHeight {
      imageAYBuffer[i] = (Float(imageAByteBuffer[i]) + Float(imageAByteBuffer[i + imageWidth * imageHeight]) + Float(imageAByteBuffer[i + 2 * imageWidth * imageHeight]))/3
      imageBYBuffer[i] = (Float(imageBByteBuffer[i]) + Float(imageBByteBuffer[i + imageWidth * imageHeight]) + Float(imageBByteBuffer[i + 2 * imageWidth * imageHeight]))/3
    }
    // gradient map
    let maskHor: [Float] = [-1.0, -2.0, -1.0,
                            0.0, 0.0, 0.0,
                            1.0, 2.0, 1.0]
    let maskVer: [Float] = [-1.0, 0.0, 1.0,
                            -2.0, 0.0, 2.0,
                            -1.0, 0.0, 1.0]
    var imageAGradXBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
    var imageAGradYBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
    var imageAGradBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)

    var imageBGradXBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
    var imageBGradYBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
    var imageBGradBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)

    vDSP_f3x3(imageAYBuffer, vDSP_Length(imageHeight), vDSP_Length(imageWidth), maskHor, &imageAGradXBuffer)
    vDSP_f3x3(imageAYBuffer, vDSP_Length(imageHeight), vDSP_Length(imageWidth), maskVer, &imageAGradYBuffer)
    vDSP_vmma(imageAGradXBuffer, 1, imageAGradXBuffer, 1, imageAGradYBuffer, 1, imageAGradYBuffer, 1, &imageAGradBuffer, 1, vDSP_Length(imageWidth * imageHeight))

    vDSP_f3x3(imageBYBuffer, vDSP_Length(imageHeight), vDSP_Length(imageWidth), maskHor, &imageBGradXBuffer)
    vDSP_f3x3(imageBYBuffer, vDSP_Length(imageHeight), vDSP_Length(imageWidth), maskVer, &imageBGradYBuffer)
    vDSP_vmma(imageBGradXBuffer, 1, imageBGradXBuffer, 1, imageBGradYBuffer, 1, imageBGradYBuffer, 1, &imageBGradBuffer, 1, vDSP_Length(imageWidth * imageHeight))

    var gradDiff: Float = 0.0
    for j in 0..<imageHeight {
      for i in 0..<imageWidth {
        gradDiff += fabs(sqrt(imageAGradBuffer[j * imageWidth + i]) - sqrt(imageBGradBuffer[j * imageWidth + i]))
      }
    }
    gradDiff /= (Float)(imageHeight * imageWidth)
//    let maskHor: [[Float]] = [[-1.0, -2.0, -1.0],
//                              [0.0, 0.0, 0.0],
//                              [1.0, 2.0, 1.0]]
//    let maskVer: [[Float]] = [[-1.0, 0.0, 1.0],
//                              [-2.0, 0.0, 2.0],
//                              [-1.0, 0.0, 1.0]]
//    var imageAGradBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
//    var imageBGradBuffer = Array<Float>(count: imageWidth * imageHeight, repeatedValue: 0.0)
//
//    var gradDiff: Float = 0.0
//    for j in 1..<imageHeight-1 {
//      for i in 1..<imageWidth-1 {
//        var gradAXTemp: Float = 0.0
//        var gradAYTemp: Float = 0.0
//        var gradBXTemp: Float = 0.0
//        var gradBYTemp: Float = 0.0
//        for m in -1...1 {
//          for n in -1...1 {
//            gradAXTemp += imageAYBuffer[(j+m) * imageWidth + (i+n)] * maskHor[m+1][n+1]
//            gradAYTemp += imageAYBuffer[(j+m) * imageWidth + (i+n)] * maskVer[m+1][n+1]
//            gradBXTemp += imageBYBuffer[(j+m) * imageWidth + (i+n)] * maskHor[m+1][n+1]
//            gradBYTemp += imageBYBuffer[(j+m) * imageWidth + (i+n)] * maskVer[m+1][n+1]
//          }
//        }
//        imageAGradBuffer[j * imageWidth + i] =
//          sqrt((gradAXTemp * gradAXTemp) + (gradAYTemp * gradAYTemp))
//        imageBGradBuffer[j * imageWidth + i] =
//          sqrt((gradBXTemp * gradBXTemp) + (gradBYTemp * gradBYTemp))
//        gradDiff += fabs(imageAGradBuffer[j * imageWidth + i] - imageBGradBuffer[j * imageWidth + i])
//      }
//    }
//    gradDiff /= Float(imageHeight * imageWidth)
//    NSLog("\(diff, gradDiff)")
    return (diff, gradDiff)
  }

  static func imageRetrieve(testImage: UIImage, imageList: [String]) -> [Float] {
    var scores = [(Float, Float)]()
    var maxScore: (Float, Float) = (FLT_MIN, FLT_MIN)
    var minScore: (Float, Float) = (FLT_MAX, FLT_MAX)
    for image in imageList {
      guard let refImage = UIImage(contentsOfFile: image) else {
        NSLog("\(image) is not an image.")
        scores.append((FLT_MAX, FLT_MAX))
        continue
      }
      let diff = ImageUtilities.similiarityMeasurement(testImage, refImage)
      scores.append(diff)
      maxScore.0 = (diff.0 > maxScore.0) ? diff.0 : maxScore.0
      minScore.0 = (diff.0 < minScore.0) ? diff.0 : minScore.0
      maxScore.1 = (diff.1 > maxScore.1) ? diff.1 : maxScore.1
      minScore.1 = (diff.1 < minScore.1) ? diff.1 : minScore.1
    }

    var normalizedScores = [(Float, Float)]()
    for i in 0..<scores.count {
      let diff0 = (scores[i].0 - minScore.0) / (maxScore.0 - minScore.0 + 0.0000001)
      let diff1 = (scores[i].1 - minScore.1) / (maxScore.1 - minScore.1 + 0.0000001)
      normalizedScores.append((diff0, diff1))
    }

    var fusedScores = Array<Float>(count: scores.count, repeatedValue: 0.0)
    for i in 0..<fusedScores.count {
//      fusedScores[i] = (normalizedScores[i].0 + normalizedScores[i].1) / 2
      fusedScores[i] = normalizedScores[i].0
    }
    return fusedScores
  }

  static func imageComparison(testImage: UIImage, _ refImage: UIImage) -> [UIImage?] {

    let rgbaTest = RGBA(image: testImage)!
    let rgbaRef = RGBA(image: refImage)!
    let rgbaDiff = RGBA(image: testImage)!

    let imageWidth = rgbaRef.width
    let imageHeight = rgbaRef.height
    let RGBAWhite: UInt32  = 0xFFFFFFFF
    let RGBABlack: UInt32 = 0xFF000000
    var heightOfStatusBar = 40
    if imageWidth != 750 {
      heightOfStatusBar = 20
    }

    for j in 0..<imageHeight {
      for i in 0..<imageWidth {
        let testY: Float = (Float(rgbaTest.pixels[j * imageWidth + i].red) +
                    Float(rgbaTest.pixels[j * imageWidth + i].green) +
                    Float(rgbaTest.pixels[j * imageWidth + i].blue))/3
        let refY: Float =  (Float(rgbaRef.pixels[j * imageWidth + i].red) +
                    Float(rgbaRef.pixels[j * imageWidth + i].green) +
                    Float(rgbaRef.pixels[j * imageWidth + i].blue))/3

        let absDiffY: UInt8 = UInt8(fabs(testY - refY))

        if j < heightOfStatusBar {
          rgbaTest.pixels[j * imageWidth + i].red = 0
          rgbaTest.pixels[j * imageWidth + i].green = 0
          rgbaTest.pixels[j * imageWidth + i].blue = 0

            rgbaDiff.pixels[j * imageWidth + i].value = RGBABlack
        } else {
          rgbaTest.pixels[j * imageWidth + i].red = absDiffY
          rgbaTest.pixels[j * imageWidth + i].green = absDiffY
          rgbaTest.pixels[j * imageWidth + i].blue = absDiffY

          if rgbaDiff.pixels[j * imageWidth + i].value != rgbaRef.pixels[j * imageWidth + i].value {
            rgbaDiff.pixels[j * imageWidth + i].value = RGBAWhite
          } else {
            rgbaDiff.pixels[j * imageWidth + i].value = RGBABlack
          }
        }
      }
    }
    let diffImage = rgbaTest.toUIImage()
    let binaryImage = rgbaDiff.toUIImage()
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
      imageRawData.append(ImageUtilities.getUInt32Buffer(image))
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
    let size = image.size
    UIGraphicsBeginImageContext(size)
    let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
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
    let resultImage = UIGraphicsGetImageFromCurrentImageContext()
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



