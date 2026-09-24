//
//  ConversationContainer.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import Foundation
import CoreData

class ConversationContainer {
    // Only one container may load the model, or Core Data can't match `Conversation` to a single entity
    static let shared = ConversationContainer()

    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "ConversationModel")
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }
    }
}

