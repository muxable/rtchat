import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    var sharedText = ""

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        var views = [String: WKWebView]()

        let messenger = engineBridge.applicationRegistrar.messenger()
        let audioChannel = FlutterMethodChannel(name: "com.rtirl.chat/audio",
                                                binaryMessenger: messenger)
        audioChannel.setMethodCallHandler {
            (call: FlutterMethodCall, result: @escaping FlutterResult) in
                switch call.method {
                case "set":
                    guard let args = call.arguments as? [String: Any],
                          let urls = args["urls"] as? [String],
                          let window = self.keyWindow
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
                    views.values.forEach { $0.reload() }
                    result(Bool(true))
                case "hasPermission":
                    result(Bool(true))
                case "requestPermission":
                    result(Bool(true))
                default:
                    result(FlutterMethodNotImplemented)
                }
        }
        
        let shareChannel = FlutterMethodChannel(name: "com.rtirl.chat/share", binaryMessenger: messenger)
        
        shareChannel.setMethodCallHandler {
            call, result in
            
            if call.method == "getSharedData" {
                result(self.sharedText)
            }
        }

        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    /// With scenes, the app delegate has no window; the web views attach to
    /// the key window of the active scene instead.
    var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }

    func handle(url: URL) {
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
    }
}

class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        // the share extension can cold launch the app with a URL.
        connectionOptions.urlContexts.forEach { appDelegate?.handle(url: $0.url) }
    }

    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        super.scene(scene, openURLContexts: URLContexts)
        URLContexts.forEach { appDelegate?.handle(url: $0.url) }
    }

    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
}
