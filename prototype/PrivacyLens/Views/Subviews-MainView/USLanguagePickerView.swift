//
//  USLanguagePickerView.swift
//  PrivacyLens
//
//  Created by zion on 9/22/26.
//

import SwiftUI

struct USLanguagePickerView: View {
    @Bindable var appModel: AppModel
    
    var body: some View {
        HStack(alignment: .top){
            Text("Speaking language: ")
                .offset(y: 10)
            
            VStack(alignment: .leading){
                Picker("Language", selection: $appModel.languageSelection){
                    Text("EN")
                        .tag(Language.en)
                    
                    Text("CH")
                        .tag(Language.zh)
                    
                    Text("JP")
                        .tag(Language.jp)
                    
                }
                .pickerStyle(.palette)
                .frame(maxWidth: 200)

                Text(appModel.languageSelection == .en ? "English" : appModel.languageSelection == .zh ? "Chinese" : "Japanese")
                    .foregroundStyle(.gray)
                    .offset(x: 12)
            }
        }
    }
}
