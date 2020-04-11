//
//  VoiceExample.swift
//  HeckVoice
//
//  Created by Arvind on 16/01/20.
//  Copyright © 2020 . All rights reserved.
//

import Foundation
import UIKit
import Speech
import SocketIO



class VoiceExample:UIViewController{

    var manager:SocketManager!
    var socketIOClient: SocketIOClient!
    var username = ""
    var langcode = ""
    var backendUrlStr = ""

    @IBAction func btnStartSpeak(_ sender: Any) {
        self.requestTranscribePermissions()
    }
    
    
    @IBAction func btnVoice(_ sender: Any) {
       // self.textSpeech(text: "हेलो अरविंड")
       // self.textSpeech(text: "kaise ho")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         self.setupListenSocketIO()
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    
    func transcribeAudio(url: URL) {
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                print(result.bestTranscription.formattedString)
            }
        }
    }
    
    
    func setupListenSocketIO(){//http://localhost:8080
     manager = SocketManager(socketURL: URL(string:backendUrlStr)!, config: [.log(true), .compress])
        let socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            socket.emit("add user", ["username":self.username,"lang":self.langcode ?? "en"])
        }
        socket.on("connect") {data, ack in
//            print("socket connected")
//            socket.emit("new message", text)
        }
//
        socket.on("new message") {data, ack in
            //guard let cur = data[0] as? Double else { return }
            print(data)
            //                    socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
            //                        socket.emit("update", ["amount": cur + 2.50])
            //                    }
            
           // ack.with("Got your curwrentAmount", "dude")
            debugPrint(data)
            if let arr = data as? [[String:Any]]{
                if let dict = arr[0] as? [String:Any]{
            if let str = dict["message"] as? String{
                self.textSpeech(text: str)
            }
            }
            }
        }
        socket.connect()
    }
    
    func textSpeech(text:String){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {   //working
            // your code here
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default, options: .defaultToSpeaker)
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("audioSession properties weren't set because of an error.")
                }
                //let str = String(describing: text.cString(using: String.Encoding.utf8))
                let utterance = AVSpeechUtterance(string: text ?? "Hello")
               // utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                 utterance.voice = AVSpeechSynthesisVoice(language:  "hi-IN")
                
                let synth = AVSpeechSynthesizer()
                synth.speak(utterance)
                
                do {
                    self.disableAVSession()
                }
            }
        }
        
     
}


private func disableAVSession() {
           do {
               try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
           } catch {
               print("audioSession properties weren't disable.")
           }
    }
    
}
