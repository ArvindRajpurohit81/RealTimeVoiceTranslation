//
//  LoginVC.swift
//  HeckVoice
//
//  Created by Arvind on 18/01/20.
//

import UIKit
import SocketIO

class LoginVC: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource {

    @IBOutlet weak var txtfldUserName: UITextField!
    var manager:SocketManager!
    var socket: SocketIOClient!
    
    @IBOutlet weak var txtfldLanguage: UITextField!
    @IBOutlet weak var pickerVw: UIPickerView!
    var backendUrlStr = ""   //Example http://192.
    
    var pickerarr = [["key":"English","langcode":"en","inputVoice":"en-IN"],["key":"Hindi","langcode":"hi","inputVoice":"hi-IN"]];
    var pickerValue :[String:Any]?
    
    @IBOutlet weak var vwToolbarPicker: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pickerVw.delegate = self
          pickerVw.dataSource = self
          pickerVw.isHidden = true
        vwToolbarPicker.isHidden = true
        txtfldLanguage.delegate = self
        txtfldUserName.delegate = self
        self.pickerValue = self.pickerarr[0]
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
    }
    

    
    func showalert(){
        let alert = UIAlertController(title: "Alert", message: "Please fill field", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // handling code
        self.view.endEditing(true)
        self.pickerVw.isHidden = true
        self.vwToolbarPicker.isHidden = true
    }
    
    func adduser(text:String){
         manager = SocketManager(socketURL: URL(string: backendUrlStr)!, config: [.log(true), .compress])
        self.socket = manager.defaultSocket
                        
            socket.on(clientEvent: .connect) {data, ack in
                     print("socket connected")
                if let langcode = self.pickerValue?["langcode"] as? String{
                    self.socket.emit("add user", ["username":text,"lang":langcode])
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                    if (self.pickerValue?["inputVoice"] as? String) != nil{
                  //  vc.languageCodeForSpeech = inputVoice
                  //  vc.socketIOClient = self.socket
                    vc.username = text
                    vc.langcode = langcode
                  }
                    vc.manager = self.manager
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            socket.connect()
    }
    
 
    @IBAction func btnAddUser(_ sender: Any) {
        self.view.endEditing(true)
        if txtfldUserName.text != ""{
            self.adduser(text: txtfldUserName.text ?? "-")
        }else{
            self.showalert()
        }
    }
    
    @IBAction func btnDone(_ sender: Any) { //Picker Toolbar Done
        if pickerValue == nil{
            pickerValue = pickerarr[0]
        }
        if let str = pickerValue?["key"] as? String{
                self.txtfldLanguage.text = str
            }
        pickerVw.isHidden = true;
        vwToolbarPicker.isHidden = true
    }
}

extension LoginVC{//Picker Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerarr.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let dict = pickerarr[row]
        if let str = dict["key"]
        {
            return str
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let dict = pickerarr[row]
        if pickerValue != nil{
            pickerValue = dict
        }
        // txtfldLanguage.text = str
    }
}


extension LoginVC:UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.txtfldLanguage{
            self.view.endEditing(true)
            pickerVw.isHidden = false
            vwToolbarPicker.isHidden = false
            return false
        }
        return true
    }
}
