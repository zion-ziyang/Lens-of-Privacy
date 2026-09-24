//
//  AppModel.swift
//  PrivacyLens
//
//  Created by Zion on 12/29/24.
//

import ARKit
import Vision
import Speech
import SwiftUI
import CoreData
import RealityKit
import AVFoundation

import GoogleGenerativeAI

@MainActor
@Observable
class AppModel {
    init(context: NSManagedObjectContext) {
        // Coredata
        viewContext = context
        // Hand Tracking (ARKit)
        rootEntity = AnchorEntity(world: .zero)
        // Transcription
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw RecognizerError.notPermittedToRecord
                }
            } catch {
                transcribe(error)
            }
        }
        // Coredata
        fetchHistoryConversations()
    }
    
    // MARK: Language
    var languageSelection = Language.en
    
    //MARK: UX
    var readyToShowResponse = false
    
    var selectedConversation: Conversation?
    
    func handelToShowDetail(_ conversion: Conversation){
        selectedConversation = conversion
    }
    
    //  ======  Core Enter Point ======
    func startTranscribing(){
        // reset all
        readyToShowPrompt = false
        readyToShowResponse = false
        requestError = nil
        transcription = ""
        Task{
            await transcribe()
            await loadMainCamera()
        }
    }
    var isInterapted = false
    func reStartTranscribing(){
        // stop possible looping waiting sound
        continueWaitingSound = false
        isInterapted = true
        // reset all
        originalPixelBuffer = nil
        originalImage = nil
        croppedPixelBuffer = nil
        croppedImage = nil
        
        // Drop a conversation that never finished, so the next save doesn't add it to history
        if let currentConversation, currentConversation.isInserted {
            viewContext.delete(currentConversation)
        }
        currentConversation = nil
        requestError = nil
        readyToShowPrompt = false
        readyToShowResponse = false
        transcription = ""
        
        isHandTracking = false
        resetHandPanel()
        
        if isTranscribing{
            finishTranscribing()
        }
        
        cameraFrameProvider = CameraFrameProvider()
        Task{
            await transcribe()
            await loadMainCamera()
        }
    }
    
    // MARK: - AI provider (ref: https://github.com/google-gemini/generative-ai-swift)
    // true: answers are read by OpenAI TTS (needs openAIKey); false: answers are read by the on-device voice
    let useOpenAITTS = true

    private let openAIUrl = URL(string: "https://api.openai.com/v1/audio/speech")
    private let openAIOrg = "xxx" // Optional
    private let openAIKey = "xxx"
    private let geminiKey = "xxx"

    var hintMessage: String {
        useOpenAITTS
        ? "By clicking Start, you agree to send the image and transcribed text to Google, and the answer to OpenAI."
        : "By clicking Start, you agree to send the image and transcribed text to Google."
    }

    // MARK: - License check
    var setupWarnings: [String] {
        var warnings: [String] = []
        if !isConfigured(geminiKey) {
            warnings.append("Gemini API key is missing. Set geminiKey in AppModel.swift.")
        }
        if useOpenAITTS && !isConfigured(openAIKey) {
            warnings.append("OpenAI API key is missing. Set openAIKey in AppModel.swift, or set useOpenAITTS to false.")
        }
        // Main camera access needs Apple's Enterprise API license, bundled as Enterprise.license
        if let licenseURL = Bundle.main.url(forResource: "Enterprise", withExtension: "license") {
            if let expirationDate = licenseExpirationDate(of: licenseURL), expirationDate < .now {
                warnings.append("Enterprise.license expired on \(expirationDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: .gmt))). Main camera access needs a renewed license from Apple.")
            }
        } else {
            warnings.append("Enterprise.license is missing. Main camera access needs an Apple Enterprise API license.")
        }
        return warnings
    }

    private func isConfigured(_ key: String) -> Bool {
        !key.isEmpty && key != "xxx"
    }

    // The license is a signed file with a plist inside it that holds `expirationDate`
    private func licenseExpirationDate(of url: URL) -> Date? {
        guard let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex),
              let plist = try? PropertyListSerialization.propertyList(from: data[start.lowerBound..<end.upperBound], format: nil) as? [String: Any] else {
            return nil
        }
        return plist["expirationDate"] as? Date
    }

    func pushRequestToGemini() async{
        let model = GenerativeModel(name: "gemini-2.0-flash", apiKey: geminiKey)
        // let model = GenerativeModel(name: "gemini-1.5-pro", apiKey: geminiKey)
        // let model = GenerativeModel(name: "gemini-2.0-flash-exp", apiKey: geminiKey)
        do{
            var prompt = ""
            switch languageSelection {
            case .en:
                prompt = "Look at the image(s), and then answer the following question: \(currentConversation?.userTxt ?? ""). "
            case .zh:
                prompt = "根据图，回答问题: \(currentConversation?.userTxt ?? "")。"
            case .jp:
                prompt = "画像を見て、次の質問に答えてください: \(currentConversation?.userTxt ?? "")。"
            }
            // Optional
            var images = [any ThrowingPartsRepresentable]()
            images.append(croppedImage!)
            let outputContentStream = model.generateContentStream(prompt, images)
            currentConversation?.createdAt_ = .now
            
            var finalResponse = ""
            for try await outputContent in outputContentStream {
                finalResponse += outputContent.text ?? ""
            }
            guard !finalResponse.isEmpty else {
                print("Gemini error: empty response")
                stopWaitingWithError()
                return
            }
            handleAndProcess(finalResponse)
        }catch{
            print("Gemini error: \(error.localizedDescription)")
            stopWaitingWithError()
        }
    }

    // Stop the waiting sound and tell the user the request failed
    private func stopWaitingWithError() {
        continueWaitingSound = false
        stopLoop()
        showRequestError("Could not get an answer from Gemini. Press restart to try again.", sound: "error_process")
    }
        
    func handleAndProcess(_ response: String){
        currentConversation?.respondTxt_ = response
        currentConversation?.respondAt_ = .now
        
        readyToShowResponse = true
        if useOpenAITTS {
            requestTTSFromOpenAI(of: response)
        } else {
            // The waiting loop stops and reads the answer with the on-device voice
            continueWaitingSound = false
        }
    }

    // MARK: - Audio Engine
    var continueWaitingSound = false
    private let soundPlayer = SoundPlayer()
    var timer: Timer?

    func activateSound(url: URL) {
        soundPlayer.play(url)
    }

    private func activateSound(name: String, toLoop: Bool = false) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else{
            print("Sound file not found")
            return
        }
        soundPlayer.play(url)

        if toLoop{
            // Start the looping with a timer
            startLoop()
        }
    }
    
    private func startLoop() {
        // Start a timer to check server response
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in // To solve the main actor-isolated  issue
                if self.continueWaitingSound {
                    self.soundPlayer.replay()
                } else if self.isInterapted{
                    self.stopLoop()
                    print("isInterapted, Stopped Loop")
                } else {
                    self.stopAndPlayAudioResponse()
                    print("Response received, Stopped Loop")
                }
            }
        }
    }
    
    private func stopLoop(){
        isInterapted = false
        timer?.invalidate()
        timer = nil
        soundPlayer.stop() // Stop any currently playing audio
    }

    private func stopAndPlayAudioResponse(){
        stopLoop() // Stop any currently playing audio

        currentConversation?.audioAt_ = .now
        saveConversation()

        guard useOpenAITTS else {
            soundPlayer.speak(currentConversation?.respondTxt ?? "", language: languageSelection.localeIdentifier)
            return
        }

        guard let audioPathString = currentConversation?.audioPath_ else{
            print("Error: No audio path was saved into the conversation")
            return
        }
        
        let documentsURL = URL.documentsDirectory
        let savedURL = documentsURL.appendingPathComponent("\(audioPathString).mp3")
        
        guard FileManager.default.fileExists(atPath: savedURL.path) else {
            print("Error: File does not exist at \(savedURL.path)")
            return
        }
        soundPlayer.play(savedURL)
    }
    
    //  ==== OpenAI TTS ====
    func requestTTSFromOpenAI(of text: String){
        guard let request = request(text) else {
            continueWaitingSound = false
            activateSound(name: "error_tts")
            return
        }
        send(request: request, target: currentConversation?.id_ ?? "tmp")
    }
    
    private var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        return session
    }()
    
    private func request(_ text: String) -> URLRequest? {
        guard let baseURL = openAIUrl else {
            return nil
        }
        
        let request = NSMutableURLRequest(url: baseURL)
        // voice: alloy, echo, fable, onyx, nova, and shimmer
        let parameters: [String: Any] = [
            "model": "tts-1",
            "voice": "shimmer",
            "response_format": "mp3",
            "speed": "0.98",  // hidden feature in OpenAI TTS! Range: 0.25 - 4.0, Default 1.0
            "input": text
        ]
        
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        if isConfigured(openAIOrg) {
            request.addValue(openAIOrg, forHTTPHeaderField: "OpenAI-Organization") // Optional
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) {
            request.httpBody = jsonData
        }
        
        return request as URLRequest
    }
    
    private func saveConversation() {
        try? viewContext.save()
        historyConversations.append(currentConversation!)
    }
    
    private func send(request: URLRequest, target id: String) {
        let task = self.urlSession.downloadTask(with: request) { urlOrNil, responseOrNil, errorOrNil in
            if let errorOrNil {
                print(errorOrNil)
                return
            }
            
            if let response = responseOrNil as? HTTPURLResponse {
                print("Response from OpenAI code: \(response.statusCode)")
            }
            
            guard let fileURL = urlOrNil else { return }
            
            do {
                let documentsURL = URL.documentsDirectory
                let savedURL = documentsURL.appendingPathComponent("\(id).mp3") // Use the ID for the MP3 filename
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                DispatchQueue.main.async {
                    self.currentConversation?.audioPath_ = id
                    // self.currentConversation?.audioAt_ = .now
                    self.continueWaitingSound = false
                    // self.saveConversation()
                }
            } catch {
                DispatchQueue.main.async {
                    self.continueWaitingSound = false
                    print ("file error: \(error)")
                    self.saveConversation()
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Transcription
    var isTranscribing: Bool = false
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    // private let recognizer: SFSpeechRecognizer?
    
    var readyToShowPrompt = false
    
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    var transcription: String = "..."{
        didSet{
            monitor()
        }
    }
    
    //  ================  * CORE * ===================
    private func monitor(){
        print("transcription: \(transcription)")
        
        if languageSelection == .en{
            let words = transcription.split(separator: " ")
            guard let _ = words.last else {
                return
            }
            // The question is between the last "question" and the first "over" after it
            if let questionIndex = words.lastIndex(where: { $0.lowercased().contains("question") }),
               let overIndex = words[(questionIndex + 1)...].firstIndex(where: { $0.lowercased() == "over" }),
               overIndex > questionIndex + 1 { // Keep listening after an empty "question over"
                isInterapted = false
                // Create a new array without the last element
                let userQuestion = words[(questionIndex + 1)..<overIndex]
                print("User question: \(userQuestion.joined(separator: " "))")
                readyToShowPrompt = true
                // cache current pixelBuffer into a buffer
                originalPixelBuffer = pixelBuffer
                Task{
                    finishTranscribing()
                }
                sendRequestWith(txt: userQuestion.joined(separator: " "))
            }
        }else{
            guard transcription.count > 5 else {
                return
            }
            var startWord = "请问"
            var endWord = "完成"
            if languageSelection == .jp{
                startWord = "質問"
                endWord = "以上"
            }
            if let lastStartRange = transcription.range(of: startWord, options: .backwards),
               let endRange = transcription.range(of: endWord, range: lastStartRange.upperBound..<transcription.endIndex) {
                let queryContent = transcription[lastStartRange.upperBound..<endRange.lowerBound]
                isInterapted = false
                // Create a new array without the last element
                
                readyToShowPrompt = true
                // cache current pixelBuffer into a buffer
                originalPixelBuffer = pixelBuffer
                Task{
                    finishTranscribing()
                }
                sendRequestWith(txt: String(queryContent))
            }
        }
    }
    
    private func sendRequestWith(txt: String){
        currentConversation = Conversation(context: viewContext)
        // Step 0: prepare and save basic info
        let uuid = UUID().uuidString // fileName
        currentConversation?.id_ = uuid
        currentConversation?.userTxt_ = txt
        currentConversation?.createdAt_ = .now
        // Step 1: Process frame from main camera
        guard originalPixelBuffer != nil else {
            showRequestError("The main camera is not ready. Press restart to try again.", sound: "error_camera")
            return
        }
        originalImage = originalPixelBuffer!.uiImage
        // save the orignal picture
        guard originalImage != nil else {
            showRequestError("Could not process the camera image. Press restart to try again.", sound: "error_process")
            return
        }
        FileManager().save(image: originalImage!, with: uuid)
        currentConversation?.imgPath_ = uuid
        
        // Step 2: Use Vision to get image area bounded by hand
        croppedPixelBuffer = handposeDetection(from: originalPixelBuffer!)
        
        guard croppedPixelBuffer != nil else {
            showRequestError("Could not process the camera image. Press restart to try again.", sound: "error_process")
            return
        }
        croppedImage = croppedPixelBuffer!.uiImage
        if croppedImage != nil{
            isReadyToShowVisual = true
            FileManager().save(image: croppedImage!, with: uuid + "_cropped")
            currentConversation?.cImgPath_ =  uuid + "_cropped"
        }else{
            showRequestError("Could not process the camera image. Press restart to try again.", sound: "error_process")
            return
        }
        // Step 3: Send request to server
        continueWaitingSound = true
        activateSound(name: "waitting", toLoop: true)

        showHandPanel()
        currentConversation?.model_ = "gemini"
        Task{
            await pushRequestToGemini()
        }
    }
    
    // Shown on the hand panel instead of an answer when a request fails
    var requestError: String?

    // Tell the user what went wrong and bring up the hand panel, which has the restart button
    private func showRequestError(_ message: String, sound: String) {
        requestError = message
        activateSound(name: sound)
        showHandPanel()
    }

    // The panel follows the left hand once hand tracking runs
    private func showHandPanel() {
        guard !isHandTracking else { return }
        print("Start Hand Tracking")
        handDataProvider = HandTrackingProvider()
        Task{
            await startHandTracking()
        }
    }

    //  ===============================================
    
    private func finishTranscribing(){
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
        isTranscribing = false
    }
    
    private func transcribe() async {
        // Set the language for transcription
        let localeLanguage = languageSelection.localeIdentifier

        print("Transcribing in \(localeLanguage)")
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeLanguage)) else {
            print("Recognizer not available for \(localeLanguage).")
            self.transcribe(RecognizerError.recognizerIsUnavailable)
            return
        }
        
        do {
            let (audioEngine, request) = try await self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
            self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
                self?.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
            })
            print("Audio recognizer prepared")
            isTranscribing = true
            let audioName = languageSelection == .en ? "hint" : languageSelection == .zh ? "hint_zh" :"hint_jp"
            activateSound(name: audioName)
        } catch {
            print("Audio recognizer init failed: \(error)")
            reset()
            transcribe(error)
            // play a hint
            let audioName = languageSelection == .en ? "error_transcribe" : languageSelection == .zh ? "error_transcribe_zh" :"error_transcribe_jp"
            activateSound(name: audioName)
            // give user panel to restart
            requestError = "Speech recognition could not start. Press restart to try again."
            showHandPanel()
        }
    }
    
    private func prepareEngine() async throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        // On visionOS the audio session follows the app's scenes, and starting the microphone can fail
        // (error 2003329396) while the main window closes. Retry with a fresh engine and session.
        let maxAttempts = 3
        var attempt = 1
        while true {
            do {
                // Activating the audio session and starting the engine block, so keep them off the main thread
                return try await Task.detached { [attempt] in
                    try AppModel.startEngine(reactivateSession: attempt > 1)
                }.value
            } catch where attempt < maxAttempts {
                print("Audio engine start failed (attempt \(attempt) of \(maxAttempts)): \(error)")
                attempt += 1
                try await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    nonisolated private static func startEngine(reactivateSession: Bool) throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioSession = AVAudioSession.sharedInstance()
        if reactivateSession {
            try? audioSession.setActive(false)
        }
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw error
        }
        return (audioEngine, request)
    }
    
    private func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            transcribe(result.bestTranscription.formattedString)
        }
    }
    
    // Reset the speech recognizer.
    private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private func transcribe(_ message: String) {
        Task {
            transcription = message
        }
    }
    
    private func transcribe(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        Task { @MainActor [errorMessage] in
            transcription = "<< \(errorMessage) >>"
        }
    }
    
    // MARK: - Hand detection (using Vision)
    var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    // MARK: - Hand Tracking to place panel(using ARKit)
    var isHandTracking = false
    var handDataProvider =  HandTrackingProvider()
    var rootEntity: AnchorEntity
    
    var leftWristTrans = matrix_identity_float4x4
    
    var previousTransform: simd_float4x4? = nil
    var previousRotation: simd_float4x4?
    
    let rotationSmoothingFactor: Float = 0.1
    let smoothingFactor: Float = 0.1
    
    private func smoothTransform(_ newTransform: simd_float4x4) -> simd_float4x4 {
        let newTranslation = simd_float3(newTransform.columns.3.x, newTransform.columns.3.y, newTransform.columns.3.z)
        
        if let previous = previousTransform {
            let previousTranslation = simd_float3(previous.columns.3.x, previous.columns.3.y, previous.columns.3.z)
            let smoothedTranslation = previousTranslation + (newTranslation - previousTranslation) * smoothingFactor
            
            var smoothedTransform = newTransform
            smoothedTransform.columns.3 = simd_float4(smoothedTranslation.x, smoothedTranslation.y, smoothedTranslation.z, 1.0)
            
            previousTransform = smoothedTransform
            return smoothedTransform
        } else {
            previousTransform = newTransform
            return newTransform
        }
    }
    
    func smoothRotation(from transform: simd_float4x4) -> simd_float4x4 {
        var smoothedTransform = transform
        
        if let previous = previousRotation {
            smoothedTransform.columns.0 = simd_mix(previous.columns.0, transform.columns.0, simd_float4(repeating: rotationSmoothingFactor))
            smoothedTransform.columns.1 = simd_mix(previous.columns.1, transform.columns.1, simd_float4(repeating: rotationSmoothingFactor))
            smoothedTransform.columns.2 = simd_mix(previous.columns.2, transform.columns.2, simd_float4(repeating: rotationSmoothingFactor))
        }
        
        // Update the stored previous rotation
        previousRotation = smoothedTransform
        return smoothedTransform
    }
    
    func startHandTracking() async {
        do {
            if HandTrackingProvider.isSupported {
                try await arKitSession.run([handDataProvider])
                isHandTracking = true
                for await update in handDataProvider.anchorUpdates {
                    switch update.event {
                    case .updated:
                        let anchor = update.anchor
                        // Publish updates only if the hand and the relevant joints are tracked.
                        guard anchor.isTracked else { continue }
                        guard let handSkeleton = anchor.handSkeleton else { continue }
                        updateFingerEnity(idPrefix: anchor.chirality.description, rootTransform: anchor.originFromAnchorTransform, skeleton: handSkeleton)
                    default:
                        break
                    }
                }
            } else {
                print("Hand tracking is not supported")
            }
        } catch {
            print("error is \(error)")
        }
    }
    
    func updateFingerEnity(idPrefix: String, rootTransform: simd_float4x4, skeleton: HandSkeleton) {
        guard idPrefix == "left" else { return }
        
        for joint in skeleton.allJoints {
            let jointName: String = "\(joint.name)"
            if jointName == "wrist"{
                if let entity = rootEntity.findEntity(named: "wrist"){
                    if joint.isTracked {
                        leftWristTrans = rootTransform * joint.anchorFromJointTransform // store it first
                        // for visualization
                        entity.setTransformMatrix(rootTransform * joint.anchorFromJointTransform, relativeTo: nil)
                        entity.scale = simd_float3(repeating: 0.1)
                        entity.isEnabled = true
                    }else{
                        
                    } // joint.isTracked
                } else{ // findEntity
                    // for visualization
                    let entity = ModelEntity(
                        mesh: .generateSphere(radius: 0.1),
                        materials: [SimpleMaterial(color: .white, isMetallic: false)]
                    )
                    entity.name = jointName
                    entity.setTransformMatrix(rootTransform * joint.anchorFromJointTransform, relativeTo: nil)
                    entity.scale = simd_float3(repeating: 0.1)
                    rootEntity.addChild(entity)
                }
            } // joint.name =
        } // for
        
        guard let originEntity = rootEntity.findEntity(named: "attachment-origin") else{
            return
        }
        // // Step 1: Low passing filter
        let smoothedTransform = smoothTransform(leftWristTrans)
        // // Step 2
        let finalTransform = smoothRotation(from: smoothedTransform)
        originEntity.setTransformMatrix(finalTransform, relativeTo: nil)
    }
    
    private func resetHandPanel(){
        guard let originEntity = rootEntity.findEntity(named: "attachment-origin") else{
            return
        }
        guard let leftWristEntity = rootEntity.findEntity(named: "wrist") else{
            return
        }
        
        let identity = matrix_identity_float4x4
        originEntity.setTransformMatrix(identity, relativeTo: nil)
        leftWristEntity.setTransformMatrix(identity, relativeTo: nil)

    }
    
    // MARK: - BASIC Data Storage (CoreData)
    var currentConversation: Conversation?
    var historyConversations: [Conversation] = []
    
    private var viewContext: NSManagedObjectContext
    
    func fetchHistoryConversations(){
        let request = NSFetchRequest<Conversation>(entityName: "Conversation")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.createdAt_, ascending: false)]
        do{
            historyConversations = try viewContext.fetch(request)
        }catch{
            print("Error fetching history conversations: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Immersive Space
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // MARK: - Main Camera Access
    private var originalPixelBuffer: CVPixelBuffer?
    private var visualizedHandPixelBuffer: CVPixelBuffer?
    private var croppedPixelBuffer: CVPixelBuffer?
    var originalImage: UIImage?
    var croppedImage: UIImage?
    
    var isMainCameraRunning = false
    var isReadyToShowVisual = false
    
    let formats = CameraVideoFormat.supportedVideoFormats(for: .main, cameraPositions: [.left])
    var cameraFrameProvider = CameraFrameProvider()
    
    var arKitSession = ARKitSession()
    var pixelBuffer: CVPixelBuffer?
    
    func loadMainCamera() async {
        do{
            if CameraFrameProvider.isSupported{
                isMainCameraRunning = true
                try await arKitSession.run([cameraFrameProvider])
                // Find the highest resolution format.
                let highResolutionFormat = formats.max { $0.frameSize.height < $1.frameSize.height }
                
                // Request an async sequence of camera frames.
                guard let highResolutionFormat,
                      let cameraFrameUpdates = cameraFrameProvider.cameraFrameUpdates(for: highResolutionFormat) else {
                    print("Main camera has no video formats. Check that Enterprise.license is valid and not expired.")
                    return
                }
                for await update in cameraFrameUpdates{
                    guard let mainCameraSample = update.sample(for: .left) else{
                        print("Frame dropped")
                        continue
                    }
                    self.pixelBuffer = mainCameraSample.pixelBuffer
                }
            } else {
                print("Main camera access is not supported. Check Enterprise.license and the main camera access entitlement.")
            }
        }catch{
            print("Main camera error: \(error.localizedDescription)")
            return
        }
    }
    
    func updateAndSaveVisualization(of pixelBuffer: CVPixelBuffer){
        visualizedHandPixelBuffer = pixelBuffer
        var fileName = currentConversation?.imgPath_ ?? "tmp"
        fileName += "_vis"
        if let visualizationImage = visualizedHandPixelBuffer!.uiImage{
            FileManager().save(image: visualizationImage, with: fileName)
            currentConversation?.vImgPath_ = fileName
        }else{
            print("Save visualization failed")
        }
    }
}

enum Language: String, CaseIterable {
    case en
    case zh
    case jp

    var localeIdentifier: String {
        switch self {
        case .en: return "en-US"
        case .zh: return "zh-CN"
        case .jp: return "ja-JP"
        }
    }
}
