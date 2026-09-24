<h1>Prototype System</h1>

This is the visionOS app used in the user study. You frame an object with your hands and ask a question out loud. The app sends the camera image and your question to Gemini. It then shows the answer on a panel on your left hand and reads the answer aloud.

<h3>Requirements</h3>

- **Apple Vision Pro.** The app needs the main camera and hand tracking, so it can't run in the simulator.
- **visionOS.** The study in the paper ran on visionOS 2. The code has been updated for visionOS 26.
- **Xcode** with the visionOS SDK.
- **Main camera access.** You need Apple's [Enterprise API](https://developer.apple.com/documentation/visionos/building-spatial-experiences-for-business-apps-with-enterprise-apis) license.
- **A Gemini API key.** Gemini answers the questions.
- **An OpenAI API key** (optional). OpenAI reads the answers aloud.

<h3>Setup</h3>

1. Open `PrivacyLens.xcodeproj`.
2. In **Signing & Capabilities**: choose the team your Enterprise license was issued to, and replace the placeholder bundle ID `com.example.PrivacyLens` with your own.
3. Put your `Enterprise.license` file in the `PrivacyLens/` folder.
4. Set your API keys in `PrivacyLens/Models/AppModel.swift`:

   | Setting | Purpose |
   | --- | --- |
   | `geminiKey` | Gemini API key. The model (`gemini-2.0-flash`) is set in `pushRequestToGemini()`. |
   | `openAIKey` | OpenAI API key for text to speech (`tts-1`). |
   | `openAIOrg` | Optional OpenAI organization ID. |
   | `useOpenAITTS` | Set to `false` if you don't use OpenAI. The on-device voice then reads the answers. |

5. Build and run on your Apple Vision Pro.

<h3>Usage</h3>

1. Choose the language you speak (English, Chinese or Japanese) and press **Start**.
2. Look at an object and frame it with both hands. The app sends the part of the image between your two thumb tips. If only one hand is in view, it sends the whole camera image.
3. We use a start word and an end word to help trim the question:

   | Language | Start word | End word | Example | Final question |
   | --- | --- | --- | --- | --- |
   | English | Question | Over | "Question what is this over" | what is this |
   | Chinese | 请问 | 完成 | "请问这是什么完成" | 这是什么 |
   | Japanese | 質問 | 以上 | "質問これは何ですか以上" | これは何ですか |

   The image is taken when the app hears the end word.
4. Your question, the cropped image and the answer appear on the panel on your left hand, and the answer is read aloud. Press **restart** on the panel to ask another question. If something fails, the panel shows what went wrong.

Past conversations are saved on the device. You can see them in the **History Chat** tab.