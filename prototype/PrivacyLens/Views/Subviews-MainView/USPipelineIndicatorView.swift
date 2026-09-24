//
//  USPipelineIndicatorView.swift
//  PrivacyLens
//
//  Created by Zion on 12/30/24.
//

import SwiftUI

struct USPipelineIndicatorView: View{
    
    var body: some View {
        VStack{
            HStack(alignment: .top, spacing: 80){
                indicatorView1
                
                indicatorView2
                
                indicatorView3
            }
            .padding(.bottom)
            
            HStack(alignment: .top, spacing: 80){
                makeIndicatorView(imageName: "ellipsis",
                                  title: "4. The answer usually comes within a few seconds.",
                                  isSystemImage: true)
                
                makeIndicatorView(imageName: "voice_indicator",
                                  title: "5. Finally, the answer will be delivered by voice.")
                
                makeIndicatorView(imageName: "hand_panel_indicator",
                                  title: "6. You can also find the answer txt on your left hand.")
            }
        }
    }
    
    var indicatorView1: some View{
        VStack{
            Rectangle()
                .fill(.clear)
                .frame(width: 100, height: 100)
                .overlay{
                    Image(systemName: "carrot")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.orange)
                }
                .padding(.bottom)
            
            Text("1. Find something you want to ask question about.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(width: 260, height: 88, alignment: .top)
        }
    }
    
    var indicatorView2: some View{
        VStack{
            Rectangle()
                .fill(.clear)
                .frame(width: 100, height: 100)
                .overlay{
                    ZStack{
                        Image(systemName: "carrot")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.orange)
                        Image("boundingBox_indicator")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                }
                .padding(.bottom)
            
            Text("2. Use your hand to draw a bounding box around it.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(width: 250, height: 88, alignment: .top)
        }
    }
    
    var indicatorView3: some View{
        VStack{
            Rectangle()
                .fill(.clear)
                .frame(width: 100, height: 100)
                .overlay{
                    Image("speak_indicator")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                }
                .padding(.bottom)
            
            Group{
                Text("3. Ask your question start with") + Text("'Question'").foregroundStyle(.orange)  + Text(" and end with ") + Text("'Over'").foregroundStyle(.orange) + Text(".")
            }
            .font(.title2)
            .multilineTextAlignment(.center)
            .frame(width: 260, height: 88, alignment: .top)
        }
    }

    
    func makeIndicatorView(imageName: String, title: String, isSystemImage: Bool = false) -> some View {
        VStack{
            Rectangle()
                .fill(.clear)
                .frame(width: 100, height: 100)
                .overlay{
                    if isSystemImage{
                        Image(systemName: imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }else{
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                }
                .padding(.bottom)
            
            Text(title)
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(width: 300, height: 66, alignment: .top)
        }
    }
}

#Preview {
    USPipelineIndicatorView()
        .padding(40)
        .glassBackgroundEffect()
}
