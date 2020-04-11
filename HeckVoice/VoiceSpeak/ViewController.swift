//
//  ViewController.swift
//  HeckVoice
//
//  Created by Arvind on 16/01/20.
//  Copyright © 2020 . All rights reserved.
//

import UIKit
import InstantSearchVoiceOverlay
import AVFoundation
import Speech
import SocketIO


class ViewController: UIViewController,AVSpeechSynthesizerDelegate{
    var manager:SocketManager!
    var socketIOClient: SocketIOClient!
    var username = ""
    var langcode = ""
    var backendUrlStr = ""
    
    // let voiceOverlayController = VoiceOverlayController()
    lazy var voiceOverlayController: VoiceOverlayController = {
        let recordableHandler = {
            // return SpeechController(locale: Locale(identifier: "en-in"))
            return SpeechController(locale: Locale(identifier:  "hi-IN"))
            // utterance.voice = AVSpeechSynthesisVoice(language:  "hi-IN")
            
            
        }
        return VoiceOverlayController(speechControllerHandler: recordableHandler)
    }()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    let button = UIButton()
    let label = UILabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let margins = view.layoutMarginsGuide
        
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        label.text = "Result Text from the Voice Input"
        
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        
        button.setTitle("Start using voice", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor(red: 255/255.0, green: 64/255.0, blue: 129/255.0, alpha: 1)
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 237/255, green: 82/255, blue: 129/255, alpha: 1).cgColor
        
        label.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(label)
        self.view.addSubview(button)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: margins.topAnchor, constant: 110),
        ])
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -10),
            button.centerYAnchor.constraint(equalTo: margins.centerYAnchor, constant: 10),
            button.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        voiceOverlayController.delegate = self
        
        // If you want to start recording as soon as modal view pops up, change to true
        voiceOverlayController.settings.autoStart = true
        voiceOverlayController.settings.autoStop = true
        voiceOverlayController.settings.showResultScreen = false
    }
      
    /*
     Speak
     */
    @objc func buttonTapped() {
        // First way to listen to recording through callbacks
        voiceOverlayController.start(on: self, textHandler: { (text, final, extraInfo) in
            print("callback: getting \(String(describing: text))")
            print("callback: is it final? \(String(describing: final))")
            if final {
                // here can process the result to post in a result screen
                Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { (_) in
                    let myString = text
                    let myAttribute = [ NSAttributedString.Key.foregroundColor: UIColor.red ]
                    let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)
                    
                    self.voiceOverlayController.settings.resultScreenText = myAttrString
                    self.voiceOverlayController.settings.layout.resultScreen.titleProcessed = "BLA BLA"
                })
            }
        }, errorHandler: { (error) in
            print("callback: error \(String(describing: error))")
        }, resultScreenHandler: { (text) in
            print("Result Screen: \(text)")
        }
        )
    }
    
    /*
     For listen we have different viewcontroller
     */
    @IBAction func btnListen(_ sender: UIButton) {
        let voiceExample = self.storyboard?.instantiateViewController(withIdentifier: "VoiceExample")  as! VoiceExample
        voiceExample.username = self.username
        voiceExample.langcode = self.langcode
        self.navigationController?.pushViewController(voiceExample, animated: true)
    }

    private func disableAVSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't disable.")
        }
    }
}

extension ViewController:VoiceOverlayDelegate{
   //speak and send to server
    
    // Second way to listen to recording through delegate
      func recording(text: String?, final: Bool?, error: Error?) {  //delegate of VoiceOverlayDelegate
        if let error = error {
          print("delegate: error \(error)")
        }
        if error == nil {
          //label.text = text
                  //your code block
            if final == true{
                self.setupSocketIO(text: text ?? "Hello")
            }
        }
      }
    
    fileprivate func setupSocketIO(text:String){//http://localhost:8080
           manager = SocketManager(socketURL: URL(string:backendUrlStr)!, config: [.log(true), .compress])
           let socket = manager.defaultSocket
           socket.on(clientEvent: .connect) {data, ack in
                    print("socket connected")
            socket.emit("add user", ["username":self.username,"lang":self.langcode ])
           }
           
           
           socket.on("connect") {data, ack in
               print("socket connected")
               socket.emit("new message", text)
           }
           
           socket.on("new message") {data, ack in
               //guard let cur = data[0] as? Double else { return }
               print(data)
               ack.with("Got your curwrentAmount", "dude")
           }
           socket.connect()
       }
}
