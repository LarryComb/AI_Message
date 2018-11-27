//
//  PhotoDelegate.swift
//  AI_Message
//
//  Created by Larry  on 11/26/18.
//  Copyright © 2018 Larry . All rights reserved.
//

/*
import Foundation
 
 
 class: ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate 

 // 1
 let cameraItem = InputBarButtonItem(type: .system)
 cameraItem.tintColor = .primary
 cameraItem.image = #imageLiteral(resourceName: "camera")
 
 // 2
 cameraItem.addTarget(
 self,
 action: #selector(cameraButtonPressed),
 for: .primaryActionTriggered
 )
 cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
 
 messageInputBar.leftStackView.alignment = .center
 messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
 
 // 3
 messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
 
 }
 
 // MARK: - Actions
 // TODO: Fix Error:Code=13 "query cancelled" UserInfo={NSLocalizedDescription=query cancelled}
 @objc private func cameraButtonPressed() {
 let picker = UIImagePickerController()
 picker.delegate = self
 
 if UIImagePickerController.isSourceTypeAvailable(.camera) {
 picker.sourceType = .camera
 } else {
 picker.sourceType = .photoLibrary
 }
 
 present(picker, animated: true, completion: nil)
 }
 
 
 private func sendPhoto(_ image: UIImage) {
 isSendingPhoto = true
 let apiKey = "CHqCsp-NH68f-sV7QnQAX51ecBE_HWP6YvRRaSKI6gJz"
 // API Version Date to initialize the Assistant API
 let version = "2018-10-15"
 
 let failure = {(error:Error) in
 
 DispatchQueue.main.async {
 self.navigationItem.title = "Image could not be processed"
 //button.isEnabled = true
 }
 
 
 print(error)
 
 }
 
 
 // MARK: - UIImagePickerControllerDelegate
 
 extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
 
 func imagePickerController(_ picker: UIImagePickerController,
 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
 picker.dismiss(animated: true, completion: nil)
 
 // 1
 if let asset = info[.phAsset] as? PHAsset {
 let size = CGSize(width: 500, height: 500)
 PHImageManager.default().requestImage(
 for: asset,
 targetSize: size,
 contentMode: .aspectFit,
 options: nil) { result, info in
 
 guard let image = result else {
 return
 }
 
 self.sendPhoto(image)
 }
 
 // 2
 } else if let image = info[.originalImage] as? UIImage {
 sendPhoto(image)
 }
 }
 
 func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
 picker.dismiss(animated: true, completion: nil)
 }
 // Method to set up the activity progress indicator view
 func instantiateActivityIndicator() {
 let size: CGFloat = 50
 let x = self.view.frame.width/2 - size
 let y = self.view.frame.height/2 - size
 
 let frame = CGRect(x: x, y: y, width: size, height: size)
 
 _ = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballScaleRipple)
 }
 
 
 
 
 
 
 
 // TODO: Erase once camera is fixed
 /*@objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
 let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
 image = chosenImage
 self.performSegue(withIdentifier: "ShowEditView", sender: self)
 dismiss(animated: true, completion: nil)
 }
 */*/
