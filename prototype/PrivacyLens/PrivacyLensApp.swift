//
//  PrivacyLensApp.swift
//  PrivacyLens
//
//  Created by Zion on 12/29/24.
//

import SwiftUI

@main
struct PrivacyLensApp: App {
    @State private var appModel = AppModel(context: ConversationContainer.shared.persistentContainer.viewContext)

    var body: some Scene {
        WindowGroup(id: "UserStudyMainWindow") {
            USMainTabView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            USImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
    }
}
