//
//  SoundPlayer.swift
//  PrivacyLens
//
//  Created by Zion on 9/24/26.
//

import AVFoundation

// Plays sounds and speech one at a time, in request order, on a serial background queue.
// Preparing an AVAudioPlayer can activate the audio session, which blocks and should not run on the main thread.
final class SoundPlayer: @unchecked Sendable { // all state is only touched on `queue`
    private let queue = DispatchQueue(label: "PrivacyLens.SoundPlayer")
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        // Let the system manage speech output instead of sharing the app's `.record` session used for transcription
        synthesizer.usesApplicationAudioSession = false
    }

    func play(_ url: URL) {
        queue.async {
            self.synthesizer.stopSpeaking(at: .immediate)
            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.prepareToPlay()
                self.player?.play()
            } catch {
                print("Error playing sound \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    // Play the current sound again from the start (used to loop the waiting sound)
    func replay() {
        queue.async {
            self.player?.play()
        }
    }

    // On-device TTS, used when OpenAI TTS is turned off
    func speak(_ text: String, language: String) {
        queue.async {
            self.player?.stop()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            self.synthesizer.speak(utterance)
        }
    }

    func stop() {
        queue.async {
            self.player?.stop()
            self.synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
