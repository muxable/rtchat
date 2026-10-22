import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  var sharedText = ""

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    var views = [String: WKWebView]()

    let messenger = engineBridge.applicationRegistrar.messenger()

    // MARK: - Audio channel

    let audioChannel = FlutterMethodChannel(
      name: "com.rtirl.chat/audio",
      binaryMessenger: messenger
    )

    audioChannel.setMethodCallHandler {
      (call: FlutterMethodCall, result: @escaping FlutterResult) in

      switch call.method {
      case "set":
        guard
          let args = call.arguments as? [String: Any],
          let urls = args["urls"] as? [String],
          let window = self.keyWindow
        else {
          result(false)
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

          let view = WKWebView(
            frame: .zero,
            configuration: configuration
          )

          view.load(URLRequest(url: urlobj))
          window.addSubview(view)
          views[url] = view
        }

        remove.forEach { url in
          views[url]?.removeFromSuperview()
          views[url] = nil
        }

        result(true)

      case "reload":
        guard
          let args = call.arguments as? [String: Any],
          let url = args["url"] as? String,
          let view = views[url]
        else {
          result(false)
          return
        }

        view.reload()
        result(true)

      case "hasPermission":
        result(true)

      case "requestPermission":
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // MARK: - Share channel

    let shareChannel = FlutterMethodChannel(
      name: "com.rtirl.chat/share",
      binaryMessenger: messenger
    )

    shareChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(
          FlutterError(
            code: "APP_UNAVAILABLE",
            message: "App delegate is unavailable.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "getSharedData":
        result(self.sharedText)
        self.sharedText = ""

      case "shareText":
        guard
          let args = call.arguments as? [String: Any],
          let text = args["text"] as? String,
          !text.trimmingCharacters(
            in: .whitespacesAndNewlines
          ).isEmpty
        else {
          result(
            FlutterError(
              code: "INVALID_TEXT",
              message: "Cannot share an empty message.",
              details: nil
            )
          )
          return
        }

        DispatchQueue.main.async {
          guard
            let rootViewController =
              self.keyWindow?.rootViewController
          else {
            result(
              FlutterError(
                code: "NO_VIEW_CONTROLLER",
                message: "Unable to present the share sheet.",
                details: nil
              )
            )
            return
          }

          // Find the currently presented view controller.
          var presenter = rootViewController

          while let presented =
            presenter.presentedViewController
          {
            presenter = presented
          }

          // Share only the supplied message text.
          let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
          )

          // Configure the popover for iPad.
          if let popover =
            activityController.popoverPresentationController
          {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
              x: presenter.view.bounds.midX,
              y: presenter.view.bounds.midY,
              width: 0,
              height: 0
            )
            popover.permittedArrowDirections = []
          }

          presenter.present(
            activityController,
            animated: true
          ) {
            result(true)
          }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }

  // MARK: - Key window

  /// With scenes, the app delegate has no window.
  /// Find the key window belonging to the active scene.
  var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first
  }

  // MARK: - Incoming share extension

  func handle(url: URL) {
    if url.scheme == "com.rtirl.chat",
      url.host == "sharetext"
    {

      let uriComponents = NSURLComponents(
        string: url.absoluteString
      )

      uriComponents?.queryItems?.forEach { item in
        if item.name == "text",
          let itemValue = item.value?.removingPercentEncoding
        {
          self.sharedText = itemValue
        }
      }
    }
  }
}

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )

    // Handle a cold launch from the share extension.
    connectionOptions.urlContexts.forEach {
      appDelegate?.handle(url: $0.url)
    }
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)

    URLContexts.forEach {
      appDelegate?.handle(url: $0.url)
    }
  }

  private var appDelegate: AppDelegate? {
    UIApplication.shared.delegate as? AppDelegate
  }
}
