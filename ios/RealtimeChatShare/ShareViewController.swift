import UIKit

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        processText()
    }
    
    func processText() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.extensionContext?.completeRequest(returningItems: nil)
        })
        
        guard let extensionContext = self.extensionContext else {
            return
        }
        
        for item in extensionContext.inputItems {
            if let extensionItem = item as? NSExtensionItem, let attachments = extensionItem.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        attachment.loadItem(forTypeIdentifier: "public.text") {
                            result, error in
                            
                            if result != nil, let resultText = result as? String, let urlEncodedString = resultText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                                self.openURL(URL(string: "com.rtirl.chat://sharetext?text=\(urlEncodedString)")!)
                            }
                        }
                        break
                    }
                }
            }
        }
    }
    
    @objc
    @discardableResult
    func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
}
