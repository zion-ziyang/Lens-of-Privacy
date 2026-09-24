//
//  User Study ContentView.swift
//  PrivacyLens
//
//  Created by Zion on 12/29/24.
//

import SwiftUI
import RealityKit

struct USContentView: View {
    @Bindable var appModel: AppModel
    @State private var showsWarnings = false
#if targetEnvironment(simulator)
#else
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    init(appModel: AppModel) {
        self._appModel = Bindable(wrappedValue: appModel)
    }
#endif

    var body: some View {
        ZStack(alignment: .top){
            VStack{
                USPipelineIndicatorView()
                    .padding(.bottom, 20)

                HStack(alignment: .top, spacing: 20){
                    USLanguagePickerView(appModel: appModel)

                    geminiIndicator
                }

                // A single warning fits here; several go behind the warning button next to Start
                if appModel.setupWarnings.count == 1{
                    setupWarningView
                        .padding(.bottom)
                }

                startButton
            }
            .padding()
        }

    }

    // Missing API keys / Enterprise license
    var setupWarningView: some View{
        VStack(alignment: .leading, spacing: 8){
            ForEach(appModel.setupWarnings, id: \.self){ warning in
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(.yellow)
    }

    @ViewBuilder
    var warningButton: some View{
        if appModel.setupWarnings.count > 1{
            Button{
                showsWarnings = true
            } label: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            .buttonBorderShape(.circle)
            .accessibilityLabel("Setup warnings")
            .popover(isPresented: $showsWarnings){
                setupWarningView
                    .frame(width: 460, alignment: .leading)
                    .padding()
            }
        }
    }

    var geminiIndicator: some View{
        HStack{
            Text("Your request will be sent to Google")
                .padding(.trailing)
            Image("gemini")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 60)
        }
        .offset(x: 60, y: -10)
    }
    
    var startButton: some View {
#if targetEnvironment(simulator)
        VStack{
            HStack{
                Button(action: {
                }, label: {
                    Text("Start User Study")
                })
                .disabled(true)

                warningButton
            }
            .padding(.bottom)
            
            Text("You need to run this app on physical device")
                .foregroundStyle(.gray)
        }
#else
        VStack{
            HStack{
                Button(action: {
                    Task { @MainActor in
                        switch appModel.immersiveSpaceState {
                        case .open:
                            appModel.immersiveSpaceState = .inTransition
                            await dismissImmersiveSpace()
                            // Don't set immersiveSpaceState to .closed because there
                            // are multiple paths to ImmersiveView.onDisappear().
                            // Only set .closed in ImmersiveView.onDisappear().
                            
                        case .closed:
                            appModel.immersiveSpaceState = .inTransition
                            switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                            case .opened:
                                // Don't set immersiveSpaceState to .open because there
                                // may be multiple paths to ImmersiveView.onAppear().
                                // Only set .open in ImmersiveView.onAppear().
                                // Close the window before the microphone starts, since the audio session follows the app's scenes
                                dismissWindow(id: "UserStudyMainWindow")
                                appModel.startTranscribing()
                                
                            case .userCancelled, .error:
                                // On error, we need to mark the immersive space
                                // as closed because it failed to open.
                                fallthrough
                            @unknown default:
                                // On unknown response, assume space did not open.
                                appModel.immersiveSpaceState = .closed
                            }
                            
                        case .inTransition:
                            // This case should not ever happen because button is disabled for this case.
                            break
                        }
                    }
                    
                }, label: {
                    Text("Start")
                })

                warningButton
            }
            .padding(.bottom)

            Text(appModel.hintMessage)
                .foregroundStyle(.gray)
        }
#endif
    }
}

#Preview {
    USMainTabView()
        .environment(AppModel(context: ConversationContainer.shared.persistentContainer.viewContext))
}
