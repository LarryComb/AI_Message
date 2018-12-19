/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Photos
import BMSCore
import Firebase
import Assistant
import MessageKit
import VisualRecognition
import FirebaseFirestore
import NVActivityIndicatorView




class ChatViewController: MessagesViewController, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  
    
    
  private let db = Firestore.firestore()
  private var reference: CollectionReference?

  // Message State
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
    
  var now = Date()
    
  // Conersation SDK
  var assistant: Assistant?
  var context: Context?
  
  // Watson Assistant Workspace
  var workspaceID: String?

  // User
  private let user: User
  private let channel: Channel
  
  private var isSendingPhoto = true {
    didSet {
      DispatchQueue.main.async {
        self.messageInputBar.leftStackViewItems.forEach { item in
          item.isEnabled = !self.isSendingPhoto
        }
      }
    }
  }
  
  private let storage = Storage.storage().reference()

  
  deinit {
    messageListener?.remove()
  }

  
  init(user: User, channel: Channel) {
    self.user = user
    self.channel = channel
    super.init(nibName: nil, bundle: nil)
    
    title = channel.name
  }
  
  

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Instantiate Assistant Instance
    self.instantiateAssistant()
    
    // Instantiate activity indicator
    self.instantiateActivityIndicator()
    
    // Registers data sources and delegates + setup views
    self.setupMessagesKit()
    
    

    
    guard let id = channel.id else {
      navigationController?.popViewController(animated: true)
      return
    }
    
    reference = db.collection(["channels", id, "thread"].joined(separator: "/"))

    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
    
    
     navigationItem.largeTitleDisplayMode = .never
     
     maintainPositionOnKeyboardFrameChanged = true
     //messageInputBar.inputTextView.tintColor = .primary
     messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
     
     messageInputBar.delegate = self
     messagesCollectionView.messagesDataSource = self
     messagesCollectionView.messagesLayoutDelegate = self
     messagesCollectionView.messagesDisplayDelegate = self
     

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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.messagesCollectionView.scrollToBottom()
    }
  // MARK: - Actions
    // TODO: Image Code Here 1
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
                    
                    print("####About to send photo \(image)")
                    self.sendPhoto(image)
            }
            
            // 2
        } else if let image = info[.originalImage] as? UIImage {
            print("Sending photo")
            sendPhoto(image)
            
            //Add firebase storage here using  a url/data
            // Track progress of upload image file to storage
            // If status will be succed then get image url of image from firebase storage
            // and save it to database
            // Then your chat roomview controller will recieve new entry in databse and download that image show it in chat room
            
            
            
            print("imageURL\(image)/")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // TODO: Erase once camera is fixed
    /*@objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
     let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
     image = chosenImage
     self.performSegue(withIdentifier: "ShowEditView", sender: self)
     dismiss(animated: true, completion: nil)
     }
     */
  
  // MARK: - Helpers
  
  private func save(_ message: Message) {
    reference?.addDocument(data: message.representation) { error in
      if let e = error {
        print("Error sending message: \(e.localizedDescription)")
        return
      }
      
      self.messagesCollectionView.scrollToBottom()
    }
  }
    //TODO: Image Code Here 2
    //Was private
   func uploadImage(_ image: UIImage, to channel: Channel, completion: @escaping (URL?) -> Void) {
    guard let channelID = channel.id else {
        print("Got here 0??")
      completion(nil)
      return
    }
    
    guard let scaledImage = image.scaledToSafeUploadSize,
      let data = scaledImage.jpegData(compressionQuality: 0.4) else {
        print("Got here 1 ??")
        completion(nil)
        return
    }
    
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    
    let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
    storage.child(channelID).child(imageName).putData(data, metadata: metadata) { meta, error in
        print("Got here?? 3")
        print("____", meta, error)
        completion(meta?.downloadURL())
    }
  }
    //TODO: Image code here 3 This code should be for IBM Visual Recognition
    //NOTE: Was private func
   func sendPhoto(_ image: UIImage) {
    isSendingPhoto = true
   let apiKey = "CHqCsp-NH68f-sV7QnQAX51ecBE_HWP6YvRRaSKI6gJz"
    // API Version Date to initialize the Assistant API
    let version = "2018-12-15"
    
    let failure = {(error:Error) in
        
        DispatchQueue.main.async {
            self.navigationItem.title = "Image could not be processed"
            //button.isEnabled = true
        }
        
        print(error)
        
    }
    
    //let recogURL = URL(string: "https://unsplash.it/50/100?image=\(randomNumber)")!
    
    uploadImage(image, to: channel) { [weak self] url in
        
        
        
      // TODO: Fix Add Watson Visual Recognition image is not being sent to Watson
        print("#### url Image: \(image) URL: \(url)")
      if let _ = self, let url = url {
        let visualRecognition = VisualRecognition(apiKey: apiKey, version: version)
        print("####STARTING RECOG")
        visualRecognition.classify(imagesFile: url) { classifiedImages in
            print("##### CLASSDIFIED IMAGES \(classifiedImages)")
            if let classifiedImage = classifiedImages.images.first {
                print("####  classifiedImage", classifiedImage.classifiers)
                
                if let classification = classifiedImage.classifiers.first?.classes.first {
                    DispatchQueue.main.async {
                    }
                }
                 print("Successful IBM Match")
            }else{
                print("#### Else statement")
                DispatchQueue.main.async {
                }
            }
        }
      }
        self?.isSendingPhoto = true   // default false 
      
      guard let url = url else {
        return
      }
      
        var message = Message(user: (self?.user)!, image: image)
      message.downloadURL = url
      
        self?.save(message)
        self?.messagesCollectionView.scrollToBottom()
    }
  }
  
  private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
    let ref = Storage.storage().reference(forURL: url.absoluteString)
    let megaByte = Int64(1 * 1024 * 1024)
    
    ref.getData(maxSize: megaByte) { data, error in
      guard let imageData = data else {
        completion(nil)
        return
      }
      
      completion(UIImage(data: imageData))
    }
  }

  private func insertNewMessage(_ message: Message) {
    guard !messages.contains(message) else {
      return
    }
    
    messages.append(message)
    messages.sort()
    
    let isLatestMessage = messages.index(of: message) == (messages.count - 1)
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      DispatchQueue.main.async {
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard var message = Message(document: change.document) else {
      return
    }

    
    switch change.type {
    case .added:
      if let url = message.downloadURL {
        downloadImage(at: url) { [weak self] image in
          guard let self = self else {
            return
          }
          guard let image = image else {
            return
          }
          
          message.image = image
          self.insertNewMessage(message)
        }
      } else {
        insertNewMessage(message)
      }

      
    default:
      break
    }
  }

}




// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                       in messagesCollectionView: MessagesCollectionView) -> UIColor {
    
    // 1
    return isFromCurrentSender(message: message) ? .primary : .incomingMessage
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
                           in messagesCollectionView: MessagesCollectionView) -> Bool {
    
    // 2
    return false
  }
  //Text Box Styling
  func messageStyle(for message: MessageType, at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    
    // 3 Creates Bubble Tail to Text Box
    return .bubbleTail(corner, .curved)
  }
}


// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath,
                  in messagesCollectionView: MessagesCollectionView) -> CGSize {
    
    // 1
    return .zero
  }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> CGSize {
    
    // 2
    return CGSize(width: 0, height: 8)
  }
  
  func heightForLocation(message: MessageType, at indexPath: IndexPath,
                         with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    
    // 3
    return 0
  }
}


// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    
    // 1
    func currentSender() -> Sender {
        return Sender(id: user.uid, displayName: AppSettings.displayName)
    }
    
    // 2
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // 3
    func messageForItem(at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
    }
    
    // 4
    func cellTopLabelAttributedText(for message: MessageType,
                                    at indexPath: IndexPath) -> NSAttributedString? {
        
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
}




// MARK: - MessageInputBarDelegate

extension ChatViewController: MessageInputBarDelegate {
  
  func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
    
    // 1
    let message = Message(user: user, content: text)
    
    // 2
    save(message)
    
    // 3
    inputBar.inputTextView.text = ""
    
    //4
    // send to watson
    sendMessageToWatson(text)
    
    //5
    // save photo to firebase
    
    
    //6 TODO: Here is were I think the problem orginates
    // send photo to watson
    //sendPhoto(UIImage)

  }

}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController {
  /*
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
  } */
    
    
    // Method to set up the activity progress indicator view
    func instantiateActivityIndicator() {
        let size: CGFloat = 50
        let x = self.view.frame.width/2 - size
        let y = self.view.frame.height/2 - size
        
        let frame = CGRect(x: x, y: y, width: size, height: size)
        
        _ = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballScaleRipple)
    }
    
    // Method to set up messages kit data sources and delegates + configure
    func setupMessagesKit() {
        
        // Register datasources and delegates
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        //messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        // Configure views
        messageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = false // default false
    }
  
    func instantiateAssistant() {
        
        // Start activity indicator
        startAnimating( message: "Connecting to Kissiko", type: NVActivityIndicatorType.ballScaleRipple)
        
        // Create a configuration path for the BMSCredentials.plist file then read in the Watson credentials
        // from the plist configuration dictionary
        guard let configurationPath = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
            let configuration = NSDictionary(contentsOfFile: configurationPath) else {
                
            showAlert(.missingCredentialsPlist)
                return
        }
        
        
        // API Version Date to initialize the Assistant API
        let date = "2018-12-12"
        
        // Set the Watson credentials for Assistant service from the BMSCredentials.plist
        // If using IAM authentication
        if let apikey = configuration["conversationApikey"] as? String,
            let url = configuration["conversationUrl"] as? String {
            
            // Initialize Watson Assistant object
            let assistant = Assistant(version: date, apiKey: apikey)
            
            // Set the URL for the Assistant Service
            assistant.serviceURL = url
            
            self.assistant = assistant
            
            // If using user/pwd authentication
        } else if let password = configuration["conversationPassword"] as? String,
            let username = configuration["conversationUsername"] as? String,
            let url = configuration["conversationUrl"] as? String {
            
            // Initialize Watson Assistant object
            let assistant = Assistant(username: username, password: password, version: date)
            
            // Set the URL for the Assistant Service
            assistant.serviceURL = url
            
            self.assistant = assistant
            
        } else {
            showAlert(.missingAssistantCredentials)
        }
        
        // Lets Handle the Workspace creation or selection from here.
        // If a workspace is found in the plist then use that WorkspaceID that is provided , otherwise
        // look up one from the service directly, Watson provides a sample so this should work directly
        if let workspaceID = configuration["workspaceID"] as? String {
            
            print("Workspace ID:", workspaceID)
            
            // Set the workspace ID Globally
            self.workspaceID = workspaceID
            
            // Ask Watson for its first message
           retrieveFirstMessage()
            
        } else {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                NVActivityIndicatorPresenter.sharedInstance.setMessage("Building Conversation Topics...")
            }
            
            // Retrieve a list of Workspaces that have been trained and default to the first one
            // You can define your own WorkspaceID if you have a specific Assistant model you want to work with
            guard let assistant = assistant else {
                return
            }
            
            
          assistant.listWorkspaces(failure: failAssistantWithError, success: workspaceList)
            
        }
    }
    
    // Method to start convesation from workspace list
    func workspaceList(_ list: WorkspaceCollection) {
        
        // Lets see if the service has any training model deployed
        guard let workspace = list.workspaces.first else {
            showAlert(.noWorkspacesAvailable)
            return
        }
        
        // Check if we have a workspace ID
        guard !workspace.workspaceID.isEmpty else {
            showAlert(.noWorkspaceId)
            return
        }
        
        // Now we have an WorkspaceID we can ask Watson Assisant for its first message
        self.workspaceID = workspace.workspaceID
        
        // Ask Watson for its first message
        retrieveFirstMessage()
        
    }
    
    // Method to handle errors with Watson Assistant
    func failAssistantWithError(_ error: Error) {
        showAlert(.error(error.localizedDescription))
    }

    func showAlert(_ error: AssistantError) {
        // Log the error to the console
        print(error)
        
        DispatchQueue.main.async {
            
            // Stop animating if necessary
            self.stopAnimating()
            
            // If an alert is not currently being displayed
            if self.presentedViewController == nil {
                // Set alert properties
                let alert = UIAlertController(title: error.alertTitle,
                                              message: error.alertMessage,
                                              preferredStyle: .alert)
                // Add an action to the alert
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                // Show the alert
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func retrieveFirstMessage() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            NVActivityIndicatorPresenter.sharedInstance.setMessage("Talking to Kissiko...")
        }
        
        guard let assistant = self.assistant else {
            showAlert(.missingAssistantCredentials)
            return
        }
        
        guard let workspace = workspaceID else {
            showAlert(.noWorkspaceId)
            return
        }
        
        // Initial assistant message from Watson
        assistant.message(workspaceID: workspace, failure: failAssistantWithError) { response in
            
            for watsonMessage in response.output.text {
                
                // Set current context
                self.context = response.context
                
                let message = Message(watsonMessage: watsonMessage)
                
                self.save(message)

                //TODO Add about 3 seconds to the response time to give a more human feel
                DispatchQueue.main.async {
                    self.stopAnimating()
                }
            }
        }
    }
    
    func sendMessageToWatson ( _ text : String ) {
        
        guard let assistant = self.assistant else {
            showAlert(.missingAssistantCredentials)
            return
        }
        
        guard let workspace = workspaceID else {
            showAlert(.noWorkspaceId)
            return
        }
        
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: ". ")

        let messageRequest = MessageRequest(input: InputData(text:cleanText), context: self.context)
        
        // Call the Assistant API
        assistant.message(workspaceID: workspace, request: messageRequest, failure: failAssistantWithError) { response in
            
            for watsonMessage in response.output.text {
                guard !watsonMessage.isEmpty else {
                    continue
                }
                // Set current context
                self.context = response.context
                let message = Message(watsonMessage: watsonMessage)
                
                self.save(message)

                
            }
            
        }

    }
    //TODO func sendPhototoWatson
//    func sendPhotoWatson ( _ image : UIImage ) {
//
//        guard let assistant = self.assistant else {
//            showAlert(.missingAssistantCredentials)
//            return
//        }
//
//        guard let workspace = workspaceID else {
//            showAlert(.noWorkspaceId)
//            return
//        }
//
//        let cleanText = image
//            //.trimmingCharacters(in: .whitespacesAndNewlines)
//            //.replacingOccurrences(of: "\n", with: ". ")
//
//        let messageRequest = MessageRequest(input: InputData( :uploadImage), context: self.context)
//
//        // Call the Assistant API
//        assistant.message(workspaceID: workspace, request: messageRequest, failure: failAssistantWithError) { response in
//
//            for watsonMessage in response.output.text {
//                guard !watsonMessage.isEmpty else {
//                    continue
//                }
//                // Set current context
//                self.context = response.context
//                let message = Message(watsonMessage: watsonMessage)
//
//                self.save(message)
//
//
//            }
//
//        }
//
//    }
    
    
}



enum AssistantError: Error, CustomStringConvertible {
    
    case invalidCredentials
    
    case missingCredentialsPlist
    
    case missingAssistantCredentials
    
    case noWorkspacesAvailable
    
    case error(String)
    
    case noWorkspaceId
    
    var alertTitle: String {
        switch self {
        case .invalidCredentials: return "Invalid Credentials"
        case .missingCredentialsPlist: return "Missing BMSCredentials.plist"
        case .missingAssistantCredentials: return "Missing Watson Assistant Credentials"
        case .noWorkspacesAvailable: return "No Workspaces Available"
        case .noWorkspaceId: return "No Workspaces Id Provided"
        case .error: return "An Error Occurred"
        }
    }
    
    var alertMessage: String {
        switch self {
        case .invalidCredentials: return "The provided credentials are invalid."
        case .missingCredentialsPlist: return "Make sure to follow the steps in the README to create the credentials file."
        case .missingAssistantCredentials: return "Make sure to follow the steps in the README to create the credentials file."
        case .noWorkspacesAvailable: return "Be sure to set up a Watson Assistant workspace from the IBM Cloud dashboard."
        case .noWorkspaceId: return "Be sure to set up a Watson Assistant workspace from the IBM Cloud dashboard."
        case .error(let msg): return msg
        }
    }
    
    var description: String {
        return self.alertTitle + ": " + self.alertMessage
    }
}

