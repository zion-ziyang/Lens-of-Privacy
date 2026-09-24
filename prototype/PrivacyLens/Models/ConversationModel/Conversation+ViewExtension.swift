//
//  Conversation+ViewExtension.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import Foundation

import UIKit
import Foundation

extension Conversation{
    public var id: String{
        id_ ?? UUID().uuidString
    }
    
    var createdAt: Date{
        createdAt_ ?? Date()
    }
    
    // vlm model
    var modelName: String{
        model_ ?? "gemini"
    }
    
    var userTxt: String{
        userTxt_ ?? ""
    }
    // Image name
    var imgPath: String{
        imgPath_ ?? ""
    }
    
    var croppedImgPath: String{
        cImgPath_ ?? ""
    }
    
    var visualizationImgPath: String{
        vImgPath_ ?? ""
    }
    
    // Text respond
    var respondTxt: String{
        respondTxt_ ?? ""
    }
    
    var respondAt: Date{
        respondAt_ ?? Date()
    }
    
    // Text to speech
    var audioPath: String{
        audioPath_ ?? ""
    }
    
    var audioAt: Date{
        audioAt_ ?? Date()
    }
    
    var audioURL: URL{
        URL.documentsDirectory.appendingPathComponent("\(audioPath_ ?? "error").mp3")
    }
    
    var image: UIImage{
        FileManager().loadImage(with: imgPath) ?? UIImage(named: "visual_placeholder")!
    }
    
    var croppedImage: UIImage{
        FileManager().loadImage(with: croppedImgPath) ?? UIImage(named: "visual_placeholder")!
    }
    
    var handVisImage: UIImage{
        FileManager().loadImage(with: visualizationImgPath) ?? UIImage(named: "visual_placeholder")!
    }
    
    var responseTimeCost: Double{
        respondAt.timeIntervalSince(createdAt)
    }
    
    var audioTimeCost: Double{
        audioAt.timeIntervalSince(respondAt)
    }
}

extension FileManager{
    func loadImage(with id: String) -> UIImage? {
        let url = URL.documentsDirectory.appendingPathComponent("\(id).jpg")
        do{
            let imageData = try Data(contentsOf: url)
            return UIImage(data: imageData)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func save(image : UIImage, with name: String){
        if let data = image.jpegData(compressionQuality: 1.0){
            do{
                let url = URL.documentsDirectory.appendingPathComponent("\(name).jpg")
                try data.write(to: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
