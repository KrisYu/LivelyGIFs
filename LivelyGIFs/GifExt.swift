//
//  GifExt.swift
//  GifExtDemo
//
//  Created by Xue Yu on 4/2/17.
//  Copyright © 2017 XueYu. All rights reserved.
//


import UIKit
import ImageIO
import MobileCoreServices

extension UIImageView{
    
    public func loadGif(data: Data){
        DispatchQueue.global().async {
            let image = UIImage.gif(data: data)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
    
    public func loadGif(url: URL){
        DispatchQueue.global().async {
            let image = UIImage.gif(url: url)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
    
}

extension UIImage{
    
    public class func gif(data: Data) -> UIImage?{
        // Create source from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else{
            print("GifExt: Source for the image doesnot exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gif(url: URL) -> UIImage?{
        guard let imageData = try? Data(contentsOf: url) else {
            print("GifExt: Cannot turn image named \"\(url)\" into NSData")
            return nil
        }
        return gif(data: imageData)
    }
    
    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage?{
        
        // kCGImageSourceShouldCache: decode or not when storing
        // kCGImageSourceTypeIdentifierHint:  source type
        
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(value: true), kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        
        let frameCount = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var gifDuration = 0.0
        
        for i in 0..<frameCount{
            guard let imageRef = CGImageSourceCreateImageAtIndex(source, i, options) else{
                print("GifExt: something wrong while get a frame of the gif")
                return nil
            }
            
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, i, options), let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,  let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else{
                print("GifExt: something wrong while get the info of the gif")
                return nil
            }
            
            gifDuration += frameDuration.doubleValue
            let image = UIImage(cgImage: imageRef)
            images.append(image)
        }
        
        let animation = UIImage.animatedImage(with: images, duration: gifDuration)
        return animation
    }
}

