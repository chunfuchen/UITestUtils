//
//  UIImage+GetPixelArray.swift
//  DNNKit
//
//  Created by Chun-Fu Chen on 5/28/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
  /// Get planar pixel (UInt8) array, plane order: R -> G -> B -> A. Red components are located in the beginning, and so on.
  /// Inside one plane, the order is raster scan.
  /// - Returns: Pixel array.
  func getPlanarPixelArray() -> [UInt8]? {
    struct Pixel {
      var value: UInt32
      var red: UInt8 {
        get { return UInt8(value & 0xFF) }
      }
      var green: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
      }
      var blue: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
      }
      var alpha: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
      }
    }

    guard let cgImage = self.CGImage else { return nil }
    let imageWidth = Int(self.size.width)
    let imageHeight = Int(self.size.height)
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = imageWidth * bytesPerPixel
    let imageData = UnsafeMutablePointer<Pixel>.alloc(imageWidth * imageHeight)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
    bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
    guard let imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
    CGContextDrawImage(imageContext, CGRect(origin: CGPointZero, size: self.size), cgImage)

    var pixelArray = Array<UInt8>(count: imageWidth * imageHeight * bytesPerPixel, repeatedValue: UInt8(0))

    for j in 0..<(imageHeight * imageWidth) {
      pixelArray[j] = imageData[j].red
      pixelArray[j + imageWidth * imageHeight] = imageData[j].green
      pixelArray[j + 2 * imageWidth * imageHeight] = imageData[j].blue
      pixelArray[j + 3 * imageWidth * imageHeight] = imageData[j].alpha
    }
    imageData.dealloc(imageWidth * imageHeight)
    return pixelArray
  }

  /// Get interleaved pixel (UInt8) array, all components (RGBA) of one pixel are contiguously stored and follow raster scan for whole image. 
  /// Inside one pixel, order is R->G->B->A.
  /// - Returns: Pixel array.
  func getInterleavedPixelArray() -> [UInt8]? {
    struct Pixel {
      var value: UInt32
      var red: UInt8 {
        get { return UInt8(value & 0xFF) }
      }
      var green: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
      }
      var blue: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
      }
      var alpha: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
      }
    }

    guard let cgImage = self.CGImage else { return nil }
    let imageWidth = Int(self.size.width)
    let imageHeight = Int(self.size.height)
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = imageWidth * bytesPerPixel
    let imageData = UnsafeMutablePointer<Pixel>.alloc(imageWidth * imageHeight)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
    bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
    guard let imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
    CGContextDrawImage(imageContext, CGRect(origin: CGPointZero, size: self.size), cgImage)

    var pixelArray = Array<UInt8>(count: imageWidth * imageHeight * bytesPerPixel, repeatedValue: UInt8(0))

    for j in 0..<(imageHeight * imageWidth) {
      pixelArray[4 * j] = imageData[j].red
      pixelArray[4 * j + 1] = imageData[j].green
      pixelArray[4 * j + 2] = imageData[j].blue
      pixelArray[4 * j + 3] = imageData[j].alpha
    }
    imageData.dealloc(imageWidth * imageHeight)
    return pixelArray
  }

}
