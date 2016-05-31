//
//  UIImage_Ext.swift
//  MobileEye
//
//  Created by JuiHsinLai on 3/22/16.
//  Copyright © 2016 Larry Lai. All rights reserved.
//

import Foundation
import UIKit
/**
 Usage:
 let originalImage = UIImage(named: "cat")
 let tintedImage = originalImage.tintWithColor(UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0))
 */
extension UIImage {

    static func setupTextImage(drawText:NSString, imageSize:CGSize, faceRect:CGRect,
                               textSize: CGFloat) -> UIImage? {
        // Setup the font specific variables
        let fontSize: CGFloat = textSize//faceRect.width * 0.5
        let textColor: UIColor = UIColor.redColor()
        let textFont: UIFont = UIFont(name: "Helvetica Bold", size: fontSize)!
        
        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [  NSFontAttributeName: textFont,
                                    NSForegroundColorAttributeName: textColor ]
        
        //Setup the image context using the passed image.
        UIGraphicsBeginImageContext(imageSize)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        CGContextSaveGState(context)
        
        var rect: CGRect
//        let orientation = exifOrientation(UIDevice.currentDevice().orientation)
//        let orientation = 2
//        switch orientation {
//        case 6: // Home on the button
//            // Rotate 90 degrees
//            let textTransform: CGAffineTransform = CGAffineTransformMakeRotation(-1.57)
//            CGContextConcatCTM(context, textTransform)
//            let px = faceRect.origin.x + faceRect.width
//            let py = faceRect.origin.y
//            // After rotating 90 degrees, the x-axis and y-axis are exchanged
//            rect = CGRectMake(py-imageSize.height, px , imageSize.width, imageSize.height)
//        case 1: // Home on the right, this is the default
//            rect = CGRectMake(faceRect.origin.x, imageSize.height-faceRect.origin.y, imageSize.width, imageSize.height)
//        case 3: // Home on the left, the image needs to rotate 180 degrees
//            let textTransform: CGAffineTransform = CGAffineTransformMakeRotation(3.14)
//            CGContextConcatCTM(context, textTransform)
//            // After rotating 180 degrees, x-axis and y-axis are inversed.
//            rect = CGRectMake(-(faceRect.origin.x + faceRect.width), (faceRect.origin.y+faceRect.height)-imageSize.height, imageSize.width, imageSize.height)
//        default:
//            rect = CGRectMake(faceRect.origin.x, imageSize.height-faceRect.origin.y, imageSize.width, imageSize.height)
//        }

      let px = faceRect.origin.x + faceRect.width
      let py = faceRect.origin.y
      rect = CGRectMake(px, py , imageSize.height, imageSize.width)

        //Now Draw the text into an image.
        drawText.drawInRect(rect, withAttributes: textFontAttributes)
        let uiimgLabel = UIGraphicsGetImageFromCurrentImageContext()
        // Restore context
        CGContextRestoreGState(context)
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        return uiimgLabel
    }    
    
    func tintWithColor(color:UIColor)->UIImage {
        
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()
        
        // flip the image
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextTranslateCTM(context, 0.0, -self.size.height)
        
        // multiply blend mode
        CGContextSetBlendMode(context, CGBlendMode.Multiply)//kCGBlendModeMultiply)
        
        let rect = CGRectMake(0, 0, self.size.width, self.size.height)
        CGContextClipToMask(context, rect, self.CGImage)
        color.setFill()
        CGContextFillRect(context, rect)
        
        // create uiimage
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    

    func scaleImageWithMaxDimension(maxDimension: CGFloat) -> UIImage {
        var scaledSize = CGSize(width: maxDimension, height: maxDimension);
        var scaleFactor: CGFloat
        
        let width = size.width
        let height = size.height
        
        if width > height {
            scaleFactor = height / width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.height * scaleFactor
        }
        else {
            scaleFactor = width / height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    
    func imageWithFixedOrientation() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale);
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        drawInRect(rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
    
    
    // rotatedPhoto = rotatedPhoto?.imageRotatedByDegrees(90, flip: false)
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
//        let radiansToDegrees: (CGFloat) -> CGFloat = {
//            return $0 * (180.0 / CGFloat(M_PI))
//        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        enum DeviceOrientation : Int {
            case PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
            PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
            PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
            PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
            PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
            PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
            PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
            PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
        }
        
        switch orientation {
        case UIDeviceOrientation.PortraitUpsideDown:
            return DeviceOrientation.PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM.rawValue
        case UIDeviceOrientation.LandscapeLeft:
            return DeviceOrientation.PHOTOS_EXIF_0ROW_TOP_0COL_LEFT.rawValue
        case UIDeviceOrientation.LandscapeRight:
            return DeviceOrientation.PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT.rawValue
        default:
            return DeviceOrientation.PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP.rawValue
        }
    }
    
}