//
//  USImmersiveView.swift
//  PrivacyLens
//
//  Created by Zion on 12/29/24.
//

import SwiftUI
import RealityKit

struct USImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        RealityView { content, attachments in
            content.add(appModel.rootEntity)
            
            if let attachment = attachments.entity(for: "Panel"){
                let entity = getOriginEntity(for: attachment)
                appModel.rootEntity.addChild(entity)
            }
        } attachments:{
            Attachment(id: "Panel") {
                USHandPanelView(appModel: appModel)
            }
        }
        .persistentSystemOverlays(.hidden)
    }
    
    func getOriginEntity(for attachment: Entity) -> Entity{
        let originEntity = Entity()
        originEntity.name = "attachment-origin"
        
        attachment.position = [0.1, 0.2, 0]
        attachment.orientation = simd_quatf(angle:  .pi, axis: [0, 1, 0]) * simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        attachment.scale *= [0.5, 0.5, 0.5]
        
        attachment.name = "panel"
        originEntity.addChild(attachment)
        return originEntity
    }
}
