//
//  Conversation+mock.swift
//  PrivacyLens
//
//  Created by Zion on 12/31/24.
//

import Foundation

extension Conversation {
    static var mock: Conversation {
        let context = ConversationContainer.shared.persistentContainer.viewContext
        let conversation = Conversation(context: context)
        conversation.id_ = UUID().uuidString
        conversation.model_ = "gemini"
        conversation.userTxt_ = "Hello, this is a mock conversation!"
        conversation.respondTxt_ = "This is a response."
        conversation.createdAt_ = Date()
        conversation.respondAt_ = Date().addingTimeInterval(60)
        conversation.imgPath_ = "xxx"
        conversation.cImgPath_ = "xxx_cropped"
        conversation.vImgPath_ = "xxx_vis"
        conversation.audioPath_ = "mockAudio"
        conversation.audioAt_ = Date().addingTimeInterval(120)
        return conversation
    }
}
