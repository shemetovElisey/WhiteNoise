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
                        print("Доступ к микрофону разрешён")
                    } else {
                        print("Доступ к микрофону запрещён")
                    }
                }
            
            case .denied: // The user has previously denied access.
            print("Доступ к микрофону запрещён//")
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
            print("Перед созданием AVAudioRecorder")
            ContentView.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            print("AVAudioRecorder создан: \(ContentView.audioRecorder != nil)")
            let started = ContentView.audioRecorder?.record() ?? false
            print("После вызова record(), started: \(started)")
            if !started {
                print("AVAudioRecorder не смог начать запись. isRecording: \(ContentView.audioRecorder?.isRecording ?? false)")
            }
        } catch {
            print("Ошибка создания AVAudioRecorder: \(error)")
        }
    }
    
    func stopRecording() {
        ContentView.audioRecorder?.stop()
        print("Recording stopped")
    }
}

#Preview {
    ContentView()
}
