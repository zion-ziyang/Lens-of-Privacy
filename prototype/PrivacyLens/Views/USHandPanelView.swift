//
//  USHandPanelView.swift
//  PrivacyLens
//
//  Created by Zion on 12/31/24.
//

import SwiftUI

struct USHandPanelView: View {
    @Bindable var appModel: AppModel
    
    var body: some View {
#if targetEnvironment(simulator)
        HStack(alignment: .top, spacing: 20){
            // Image Place
            // RoundedRectangle(cornerRadius: 12)
            //     .fill(.background)
            //     .frame(width: 200, height: 200)
            //     .overlay{
            Image("visual_placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            // }
            // Conversation Place
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .frame(width: 300, height: 300)
            
            // Action Place
            VStack(alignment: .leading, spacing: 10){
                Button(action: {
                    
                }, label: {
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 25)
                        .padding()
                })
                Text("Press to restart")
                    .foregroundStyle(.gray)
                
                Button(action: {
                    
                }, label: {
                    Image(systemName: "pip")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 25)
                        .padding()
                })
                Text("Open Home")
                    .foregroundStyle(.gray)
            }
        }
        .padding(40)
        .glassBackgroundEffect()
#else
        HStack(alignment: .top, spacing: 20){
            // Image Place
            if appModel.isReadyToShowVisual{
                if let image = appModel.croppedImage{
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.clear)
                        .frame(width: 280, height: 210)
                        .overlay{
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: 280, maxHeight: 210, alignment: .top)
                        }
                        
                        .transition(.blurReplace())
                }else{
                    Image("visual_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .transition(.blurReplace())
                }
            }else{
                Image("visual_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .transition(.blurReplace())
            }
            // Conversation Place
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .frame(width: 300, height: 400)
                .overlay{
                    ScrollView{
                        VStack{
                            HStack{
                                Spacer()
                                Text(appModel.currentConversation?.userTxt ?? "")
                                    .padding()
                                    .background(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .frame(maxWidth: 260, alignment: .topTrailing)
                                    .opacity(appModel.readyToShowPrompt ? 1 : 0)
                            }
                            .padding(.trailing)
                            .padding(.top)
                            
                            ZStack(alignment: .topLeading){
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding()
                                    .opacity(appModel.readyToShowResponse || appModel.requestError != nil ? 0 : appModel.readyToShowPrompt ? 1 : 0)
                                
                                if let requestError = appModel.requestError{
                                    Text(requestError)
                                        .foregroundStyle(.orange)
                                        .padding()
                                        .frame(maxWidth: 260, alignment: .topLeading)
                                }
                                
                                HStack{
                                    VStack(alignment: .leading){
                                        Text(appModel.currentConversation?.respondTxt ?? "")
                                            .padding()
                                            .background(.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text("Text: \(appModel.currentConversation?.responseTimeCost ?? 0) s")
                                            .font(.caption)
                                        Text("Audio: \(appModel.currentConversation?.audioTimeCost ?? 0) s")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: 260, alignment: .topLeading)
                                    Spacer()
                                }
                                .padding(.bottom)
                                .opacity(appModel.readyToShowResponse ? 1 : 0)
                            }
                            .padding(.leading)
                        }
                    }
                }
            
            // Action Place
            VStack(alignment: .leading, spacing: 20){
                Button(action: {
                    appModel.reStartTranscribing()
                }, label: {
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 25)
                        .padding()
                })
                Text("Press to restart")
                    .foregroundStyle(.gray)
            }
        }
        .padding(40)
        .glassBackgroundEffect()
#endif
    }
}

#Preview {
    USHandPanelView(appModel: AppModel(context: ConversationContainer.shared.persistentContainer.viewContext))
}
