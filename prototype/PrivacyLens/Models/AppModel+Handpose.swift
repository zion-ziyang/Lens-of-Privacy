//
//  AppModel+Handpose.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import Foundation

import UIKit
import Vision

extension AppModel {
    func handposeDetection(from imageBuffer: CVPixelBuffer) -> CVPixelBuffer{
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            // get the first hand
            guard let observation = self.handPoseRequest.results?.first else {
                return imageBuffer
            }
            guard let (firstPoint, firstThumbTip, firstIndexTip) = getCrossAnchorPoint(from: observation) else{
                return imageBuffer
            }
            
            // get the second hand
            var tmpPoint: CGPoint?
            var tmpIndexTip: CGPoint?
            var tmpThumbTip: CGPoint?
            if self.handPoseRequest.results?.count ?? 0 > 1{
                guard let secondObservation = self.handPoseRequest.results?.last else {
                    return imageBuffer
                }
                let result = getCrossAnchorPoint(from: secondObservation)
                tmpPoint = result?.0
                tmpThumbTip = result?.1
                tmpIndexTip = result?.2
            }
            if let secondPoint = tmpPoint,
               let secondThumbTip = tmpThumbTip,
               let secondIndexTip = tmpIndexTip {
                // save the detected Point for visulization
                drawPointsOnYUVPixelBuffer(pixelBuffer: imageBuffer, points: [firstPoint, secondPoint, firstIndexTip, firstThumbTip, secondThumbTip, secondIndexTip])
                // return cropYUVPixelBuffer(imageBuffer, point1: firstPoint, point2: secondPoint) ?? imageBuffer
                return cropYUVPixelBuffer(imageBuffer, point1: firstThumbTip, point2: secondThumbTip) ?? imageBuffer
            }else{
                // save the detected Point for visulization
                drawPointsOnYUVPixelBuffer(pixelBuffer: imageBuffer, points: [firstThumbTip, firstIndexTip])
                return imageBuffer //cropYUVPixelBuffer(imageBuffer, point1: firstThumbTip, point2: firstIndexTip) ?? imageBuffer
            }
        }catch {
            return imageBuffer
        }
    }
    
    func getCrossAnchorPoint(from observation: VNHumanHandPoseObservation) -> (CGPoint, CGPoint, CGPoint)?{
        do{
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
            
            // Look for tip points.
            guard let thumbTipPoint = thumbPoints[.thumbTip],
                  // let thumbIP = thumbPoints[.thumbIP],
                  let indexTipPoint = indexFingerPoints[.indexTip],
                  let indexMCP = indexFingerPoints[.indexMCP] else{
                return nil
            }
            let thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            // let thumbKnuckle = CGPoint(x: thumbIP.location.x, y: 1 - thumbIP.location.y)
            let indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
            let indexKnuckle = CGPoint(x: indexMCP.location.x, y: 1 - indexMCP.location.y)
            
            let projection = calculateProjection(thumbTip: thumbTip,
                                                 indexTip: indexTip, indexKnuckle: indexKnuckle)
            return (projection ?? CGPoint(x: 0, y: 0), thumbTip, indexTip)
            
        }catch{
            return nil
        }
    }
    
    func calculateProjection(thumbTip: CGPoint,
                             indexTip: CGPoint, indexKnuckle: CGPoint) -> CGPoint? {
        // Extract coordinates
        let x1 = thumbTip.x, y1 = thumbTip.y
        let x3 = indexTip.x, y3 = indexTip.y
        let x4 = indexKnuckle.x, y4 = indexKnuckle.y

        // Calculate the components of the line vector
        let lineDx = x4 - x3
        let lineDy = y4 - y3

        // Calculate the vector from the indexTip to the thumbTip
        let vectorDx = x1 - x3
        let vectorDy = y1 - y3

        // Calculate the dot products
        let dotProductVL = vectorDx * lineDx + vectorDy * lineDy
        let dotProductLL = lineDx * lineDx + lineDy * lineDy

        // If the line length is 0, return nil (degenerate case)
        if dotProductLL == 0 {
            return nil
        }

        // Calculate the projection scalar t
        let t = dotProductVL / dotProductLL

        // Calculate the projection point
        let projectionX = x3 + t * lineDx
        let projectionY = y3 + t * lineDy

        return CGPoint(x: projectionX, y: projectionY)
    }
    
    func drawPointsOnYUVPixelBuffer(pixelBuffer: CVPixelBuffer, points: [CGPoint], dotValue: UInt8 = 255, dotRadius: Int = 10){
        // Lock the base address for the original pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        // Get the width, height, and plane information
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
              let uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) else {
            print("Failed to access planes of the pixel buffer.")
            return
        }
        
        let yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
        
        // Create a new pixel buffer to copy the modified data into
        var newPixelBuffer: CVPixelBuffer?
        let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormatType,
            nil,
            &newPixelBuffer
        )
        
        guard status == kCVReturnSuccess, let outputPixelBuffer = newPixelBuffer else {
            print("Failed to create new pixel buffer.")
            return
        }
        
        CVPixelBufferLockBaseAddress(outputPixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(outputPixelBuffer, .readOnly) }
        
        guard let newYPlane = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0),
              let newUVPlane = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1) else {
            print("Failed to access planes of the new pixel buffer.")
            return
        }
        
        // Copy the original pixel buffer to the new one
        memcpy(newYPlane, yPlane, yBytesPerRow * height)
        memcpy(newUVPlane, uvPlane, uvBytesPerRow * (height / 2))
        
        // Draw the points on the Y plane
        for point in points {
            let centerX = Int(point.x * CGFloat(width))
            let centerY = Int(point.y * CGFloat(height))
            
            for y in max(0, centerY - dotRadius)...min(height - 1, centerY + dotRadius) {
                for x in max(0, centerX - dotRadius)...min(width - 1, centerX + dotRadius) {
                    let dx = x - centerX
                    let dy = y - centerY
                    if dx * dx + dy * dy <= dotRadius * dotRadius {
                        let yOffset = y * yBytesPerRow + x
                        newYPlane.advanced(by: yOffset).storeBytes(of: dotValue, as: UInt8.self)
                    }
                }
            }
        }
        updateAndSaveVisualization(of: outputPixelBuffer)
    }
    
    func cropYUVPixelBuffer(
        _ imageBuffer: CVPixelBuffer,
        point1: CGPoint,
        point2: CGPoint
    ) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0),
              let uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1) else {
            print("Failed to access planes of the pixel buffer.")
            return nil
        }
        
        let yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1)
        
        let normalizedTopLeft = CGPoint(
            x: min(point1.x, point2.x),
            y: min(point1.y, point2.y)
        )
        let normalizedBottomRight = CGPoint(
            x: max(point1.x, point2.x),
            y: max(point1.y, point2.y)
        )
        
        let startX = Int(normalizedTopLeft.x * CGFloat(width))
        let startY = Int(normalizedTopLeft.y * CGFloat(height))
        let endX = Int(normalizedBottomRight.x * CGFloat(width))
        let endY = Int(normalizedBottomRight.y * CGFloat(height))
        
        let cropWidth = max(0, min((endX - startX) & ~1, (width - startX) & ~1)) // Ensure even width
        let cropHeight = max(0, min((endY - startY) & ~1, (height - startY) & ~1)) // Ensure even height
        
        guard startX >= 0, startY >= 0, cropWidth > 0, cropHeight > 0,
              startX + cropWidth <= width, startY + cropHeight <= height else {
            print("Invalid crop dimensions or out-of-bounds access.")
            return nil
        }
        
        let uvStartX = (startX / 2) & ~1 // Align to even UV block
        let uvStartY = (startY / 2) & ~1 // Align to even UV block
        let uvCropWidth = cropWidth / 2
        let uvCropHeight = cropHeight / 2
        
        var newPixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferBytesPerRowAlignmentKey: cropWidth
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            cropWidth,
            cropHeight,
            CVPixelBufferGetPixelFormatType(imageBuffer),
            pixelBufferAttributes as CFDictionary,
            &newPixelBuffer
        )
        guard status == kCVReturnSuccess, let outputPixelBuffer = newPixelBuffer else {
            print("Failed to create new pixel buffer.")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(outputPixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(outputPixelBuffer, []) }
        
        guard let newYPlane = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0),
              let newUVPlane = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1) else {
            print("Failed to access planes of the new pixel buffer.")
            return nil
        }
        
        // Copy the Y plane
        let newYBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(newPixelBuffer!, 0)
        for y in 0..<cropHeight {
            let srcRow = yPlane.advanced(by: (startY + y) * yBytesPerRow + startX)
            let dstRow = newYPlane.advanced(by: y * newYBytesPerRow)
            memcpy(dstRow, srcRow, cropWidth)
        }
        
        // Copy the UV plane
        let newUVBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(newPixelBuffer!, 1) // Destination UV stride
        for uvY in 0..<uvCropHeight {
            let srcRow = uvPlane.advanced(by: (uvStartY + uvY) * uvBytesPerRow + uvStartX * 2) // Each UV pixel is 2 bytes
            let dstRow = newUVPlane.advanced(by: uvY * newUVBytesPerRow)
            memcpy(dstRow, srcRow, uvCropWidth * 2) // Copy only the valid cropped UV data
        }
        
        // Fill excess chroma rows to prevent green edges
        if uvCropHeight % 2 != 0 || uvCropWidth % 2 != 0 {
            for uvY in uvCropHeight..<uvCropHeight {
                let dstRow = newUVPlane.advanced(by: uvY * newUVBytesPerRow)
                memset(dstRow, 128, uvCropWidth * 2) // Neutral chroma: 128 for U and V
            }
        }
        
        return outputPixelBuffer
    }
}
