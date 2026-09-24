//
//  USDetailView.swift
//  PrivacyLens
//
//  Created by Zion on 12/31/24.
//

import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct USDetailView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss
    let conversation: Conversation
    
    @State private var configuration: Waveform.Configuration = Waveform.Configuration(
        style: .striped(Waveform.Style.StripeConfig(color: .white, width: 3, lineCap: .round)),
            verticalScalingFactor: 0.9)
    
    var body: some View {
        VStack(spacing: 20){
            HStack(alignment: .top, spacing: 20){
                VStack(alignment: .trailing){
                    // Original Image Place
                    Text("Image from Main Camera")
                    Image(uiImage: conversation.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(width: 200, alignment: .topTrailing)
                    
                    // Hand Image Place
                    Text("Hand key points")
                    Image(uiImage: conversation.handVisImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: 200, alignment: .topTrailing)
                    
                    // Cropped Image Place
                    Text("Image sent to VLM")
                    Image(uiImage: conversation.croppedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: 200, alignment: .topTrailing)
                }
                .frame(height: 500)
                
                // Conversation Place
                ZStack(alignment: .bottom){
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .frame(width: 300, height: 500)
                        .overlay{
                            ScrollView{
                                VStack{
                                    HStack{
                                        Spacer()
                                        Text(conversation.userTxt)
                                            .padding()
                                            .background(.black)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .frame(maxWidth: 260, alignment: .topTrailing)
                                    }
                                    .padding(.trailing)
                                    .padding(.top)
                                    
                                    HStack{
                                        VStack(alignment: .leading){
                                            Text(conversation.respondTxt)
                                                .padding()
                                                .background(.blue)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            Text("\(conversation.responseTimeCost) s")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: 260, alignment: .topLeading)
                                        Spacer()
                                    }
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.clear)
                                        .frame(height: 60)
                                }
                                .padding(.leading)
                            }
                        }
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(width: 280, height: 50)
                        .overlay{
                            HStack{
                                Text("Answered by")
                                Image(conversation.modelName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(8)
                            }
                        }
                        .padding(.bottom, 10)
                }
            }
            
            HStack(spacing: 20){
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue)
                    .frame(width: 115, height: 70)
                    .overlay{
                        Label("Exit", systemImage: "arrow.backward")
                            .font(.title2)
                    }
                    .hoverEffect()
                    .onTapGesture {
                        dismiss()
                    }
                
                RoundedRectangle(cornerRadius: 70)
                    .fill(.background)
                    .frame(width: 70, height: 70)
                    .overlay{
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(conversation.audioPath == "" ? .gray : .white)
                            .padding(15)
                    }
                    .hoverEffect()
                    .onTapGesture {
                        appModel.activateSound(url: conversation.audioURL)
                    }
                    .disabled(conversation.audioPath == "")
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .frame(width: 300, height: 70)
                    .overlay{
                        if conversation.audioPath == ""{
                            Text("No Audio")
                        }else{
                            WaveformView(audioURL: conversation.audioURL,
                                         configuration: configuration) { waveformShape in
                                waveformShape
                                    .stroke(LinearGradient(colors: [.white], startPoint: .zero, endPoint: .topTrailing),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            } placeholder: {
                                ProgressView()
                            }
                            .padding()
                        }
                    }
            }
        }
        .padding(40)
        .glassBackgroundEffect()
    }
}

#Preview {
    USDetailView(conversation: Conversation.mock)
        .environment(AppModel(context: ConversationContainer.shared.persistentContainer.viewContext))
}
