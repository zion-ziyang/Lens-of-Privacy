//
//  USHistroyConversationView.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import SwiftUI

struct USHistroyConversationView: View {
    @Environment(AppModel.self) var appModel
    @State private var showConversationDetail = false
    
    private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()

    
    var body: some View {
        VStack{
            List{
                ForEach(appModel.historyConversations) { conversation in
                    HStack{
                        Text("\(dateFormatter.string(from: conversation.createdAt))")
                        
                        VStack{
                            HStack{
                                Spacer()
                                Text(conversation.userTxt)
                                    .padding()
                                    .background(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .frame(maxWidth: 300, alignment: .topTrailing)
                                    .lineLimit(1)
                            }
                            .padding(.trailing)
                            
                            HStack{
                                Text(conversation.respondTxt)
                                    .padding()
                                    .background(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .frame(maxWidth: 300, alignment: .topLeading)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.leading)
                        }
                        .frame(height: 100)
                        
                        VStack(alignment: .leading){
                            HStack{
                                Image(uiImage: conversation.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding()
                                
                                Image(uiImage: conversation.handVisImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding()
                                
                                Image(uiImage: conversation.croppedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding()
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.clear)
                                    .frame(width: 100, height: 100)
                                    .overlay{
                                        Image(systemName: conversation.audioPath == "" ? "speaker.slash.circle.fill" : "speaker.wave.2.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .padding()
                                    }
                            }
                        }
                        .frame(maxHeight: 100)
                    }
                    .padding(.trailing)
                    .onTapGesture {
                        appModel.handelToShowDetail(conversation)
                        showConversationDetail.toggle()
                    }
                }
            }
            .padding()
            Text("\(appModel.historyConversations.count) history conversations founded")
        }
        .padding(40)
        .glassBackgroundEffect()
        .sheet(isPresented: $showConversationDetail, content: {
            USDetailView(conversation: appModel.selectedConversation!)
        })
    }
}
