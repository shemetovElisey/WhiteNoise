//
//  ContentView.swift
//  WhiteNoise
//
//  Copyright (c) 2025 Elisey Shemetov. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isRecording = false
    static var audioRecorder: AVAudioRecorder?
    
    var body: some View {
        VStack {
            Button(isRecording ? "stop_recording_button".localized : "start_recording_button".localized) {
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
                        LogManager.shared.info("microphone_access_granted".localized, component: .contentView)
                    } else {
                        LogManager.shared.warning("microphone_access_denied".localized, component: .contentView)
                    }
                }
            
            case .denied: // The user has previously denied access.
            LogManager.shared.warning("microphone_access_denied".localized, component: .contentView)
                return

            case .restricted:
                return
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
            LogManager.shared.debug("before_creating_audiorecorder".localized, component: .contentView)
            ContentView.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            LogManager.shared.debug("audiorecorder_created".localized(with: String(ContentView.audioRecorder != nil)), component: .contentView)
            let started = ContentView.audioRecorder?.record() ?? false
            LogManager.shared.debug("after_record_call".localized(with: String(started)), component: .contentView)
            if !started {
                LogManager.shared.error("audiorecorder_failed".localized(with: String(ContentView.audioRecorder?.isRecording ?? false)), component: .contentView)
            }
        } catch {
            LogManager.shared.error("audiorecorder_error".localized(with: String(describing: error)), component: .contentView)
        }
    }
    
    func stopRecording() {
        ContentView.audioRecorder?.stop()
        LogManager.shared.info("recording_stopped".localized, component: .contentView)
    }
}

#Preview {
    ContentView()
}