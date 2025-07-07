//
//  ContentView.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isRecording = false
    static var audioRecorder: AVAudioRecorder?
    
    var body: some View {
        VStack {
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                if isRecording {
                    stopRecording()
                } else {
                    requestMicrophoneAccessAndStartRecording()
                }
                isRecording.toggle()
            }
        }
        .frame(width: 300, height: 200)
    }
    
    func requestMicrophoneAccessAndStartRecording() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
            startRecording()
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if granted {
                        startRecording()
                        LogManager.shared.info("Доступ к микрофону разрешён", component: "ContentView")
                    } else {
                        LogManager.shared.warning("Доступ к микрофону запрещён", component: "ContentView")
                    }
                }
            
            case .denied: // The user has previously denied access.
            LogManager.shared.warning("Доступ к микрофону запрещён", component: "ContentView")
                return


            case .restricted:return
        @unknown default:
            fatalError()
        }
    }
    
    func startRecording() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent("test.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            LogManager.shared.debug("Перед созданием AVAudioRecorder", component: "ContentView")
            ContentView.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            LogManager.shared.debug("AVAudioRecorder создан: \(ContentView.audioRecorder != nil)", component: "ContentView")
            let started = ContentView.audioRecorder?.record() ?? false
            LogManager.shared.debug("После вызова record(), started: \(started)", component: "ContentView")
            if !started {
                LogManager.shared.error("AVAudioRecorder не смог начать запись. isRecording: \(ContentView.audioRecorder?.isRecording ?? false)", component: "ContentView")
            }
        } catch {
            LogManager.shared.error("Ошибка создания AVAudioRecorder: \(error)", component: "ContentView")
        }
    }
    
    func stopRecording() {
        ContentView.audioRecorder?.stop()
        LogManager.shared.info("Recording stopped", component: "ContentView")
    }
}

#Preview {
    ContentView()
}
