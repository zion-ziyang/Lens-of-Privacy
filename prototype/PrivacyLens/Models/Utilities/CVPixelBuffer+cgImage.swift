//
//  CVPixelBuffer+cgImage.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import UIKit
import AVFoundation

extension CVPixelBuffer {
    var cgImage: CGImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return cgImage
    }
    
    var uiImage: UIImage? {
        guard let cgImage = cgImage else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
