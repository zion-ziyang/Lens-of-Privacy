//
//  USMainTabView.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import SwiftUI

struct USMainTabView: View {
    @Environment(AppModel.self) var appModel
    var body: some View {
        TabView{
            Tab("Main View", systemImage: "plus"){
                USContentView(appModel: appModel)
            }
            
            Tab("History Chat", systemImage: "clock"){
                USHistroyConversationView()
            }
        }
        .glassBackgroundEffect()
    }
}

#Preview {
    USMainTabView()
        .environment(AppModel(context: ConversationContainer.shared.persistentContainer.viewContext))
}
