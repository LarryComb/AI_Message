//
//  SlidingController.swift
//  AI_Message
//
//  Created by Larry  on 7/29/18.
//  Copyright © 2018 Larry . All rights reserved.
//

import UIKit
import Firebase

class SlidingController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    
    lazy var  inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Tell me something..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInputComponents()
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(ChatMessageBox.self, forCellWithReuseIdentifier: "cellId")
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 19
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath)
        //cell.backgroundColor = .blue
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
        
    }
    
    func setupInputComponents() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        //iOS9 constraints anchors
        //x,y,w,h
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        //x,y,w,
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
 
        
        containerView.addSubview(inputTextField)
        //x,y,w,h
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separateLineView = UIView()
        separateLineView.backgroundColor = UIColor.lightGray
        separateLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separateLineView)
        //x,y,w,h
        separateLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separateLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separateLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separateLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    
    }
    //message is handle here
    @objc func handleSend() {
        
        let messageDataBase = Database.database().reference().child("Message")
        let messageDictionary = ["text": inputTextField.text!]
        //messageDataBase.updateChildValues(values)
        messageDataBase.childByAutoId().setValue(messageDictionary){
            (error, reference) in
            
            if error != nil {
                print(error!)
            }else{
                print("Message Saved Success")
                self.inputTextField.text = ""
            }
                
            
        }
        
        
    }

  
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        
        return true
    }
    
    
    
}

