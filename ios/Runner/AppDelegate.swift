import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    var sharedText = ""
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        var views = [String: WKWebView]()

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let audioChannel = FlutterMethodChannel(name: "com.rtirl.chat/audio",
                                                binaryMessenger: controller.binaryMessenger)
        audioChannel.setMethodCallHandler {
            (call: FlutterMethodCall, result: @escaping FlutterResult) in
                switch call.method {
                case "set":
                    guard let args = call.arguments as? [String: Any],
                          let urls = args["urls"] as? [String],
                          let window = self.window
                    else {
                        result(Bool(false))
                        return
                    }
                    let add = Set(urls).subtracting(views.keys)
                    let remove = Set(views.keys).subtracting(urls)

                    add.forEach { url in
                        guard let urlobj = URL(string: url) else {
                            return
                        }
                        let configuration = WKWebViewConfiguration()
                        configuration.allowsInlineMediaPlayback = true
                        configuration.allowsAirPlayForMediaPlayback = true
                        configuration.allowsPictureInPictureMediaPlayback = false
                        configuration.mediaTypesRequiringUserActionForPlayback = []

                        let view = WKWebView(frame: .zero, configuration: configuration)
                        view.load(URLRequest(url: urlobj))
                        window.addSubview(view)
                        views[url] = view
                    }
                    remove.forEach { url in
                        views[url]?.removeFromSuperview()
                        views[url] = nil
                    }
                    result(Bool(true))
                case "reload":
                    guard let args = call.arguments as? [String: Any],
                          let url = args["url"] as? String,
                          let view = views[url]
                    else {
                        result(Bool(false))
                        return
                    }

                    view.reload()
                    result(Bool(true))
                case "hasPermission":
                    result(Bool(true))
                case "requestPermission":
                    result(Bool(true))
                default:
                    result(FlutterMethodNotImplemented)
                }
        }
        
        let shareChannel = FlutterMethodChannel(name: "com.rtirl.chat/share", binaryMessenger: controller.binaryMessenger)
        
        shareChannel.setMethodCallHandler {
            call, result in
            
            if call.method == "getSharedData" {
                result(self.sharedText)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.scheme == "com.rtirl.chat", url.host == "sharetext" {
            // This means that the app was launched from the share extension
            let uriComponents = NSURLComponents(string: url.absoluteString)
            
            uriComponents?.queryItems?.forEach {
                item in
                
                if item.name == "text", let itemValue = item.value?.removingPercentEncoding {
                    self.sharedText = itemValue
                }
            }
        }
        
        return true
    }
}
