import Flutter
import UIKit

final class ScreenSecurityManager {
  private let channelName = "com.myapp.screen_security"
  private weak var window: UIWindow?
  private var channel: FlutterMethodChannel?
  private var observerTokens: [NSObjectProtocol] = []
  private var protectionCount = 0
  private var isObserving = false
  private var privacyOverlay: UIView?

  init(window: UIWindow?, binaryMessenger: FlutterBinaryMessenger) {
    self.window = window
    channel = FlutterMethodChannel(name: channelName, binaryMessenger: binaryMessenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  deinit {
    removeObservers()
    removePrivacyOverlay()
  }

  private func handle(call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "enableProtection":
      enableProtection()
      result(nil)
    case "disableProtection":
      disableProtection()
      result(nil)
    case "isScreenCaptured":
      result(UIScreen.main.isCaptured)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func enableProtection() {
    protectionCount += 1
    guard !isObserving else {
      updateCaptureState()
      return
    }

    isObserving = true
    let notificationCenter = NotificationCenter.default

    observerTokens.append(
      notificationCenter.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.updateCaptureState()
      }
    )

    observerTokens.append(
      notificationCenter.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.channel?.invokeMethod("screenshotTaken", arguments: nil)
      }
    )

    observerTokens.append(
      notificationCenter.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.updateCaptureState()
      }
    )

    observerTokens.append(
      notificationCenter.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.showPrivacyOverlay()
      }
    )

    updateCaptureState()
  }

  private func disableProtection() {
    if protectionCount > 0 {
      protectionCount -= 1
    }

    guard protectionCount == 0 else { return }
    removeObservers()
    removePrivacyOverlay()
    channel?.invokeMethod("screenCaptureStopped", arguments: nil)
  }

  private func removeObservers() {
    let notificationCenter = NotificationCenter.default
    observerTokens.forEach { notificationCenter.removeObserver($0) }
    observerTokens.removeAll()
    isObserving = false
  }

  private func updateCaptureState() {
    if UIScreen.main.isCaptured {
      showPrivacyOverlay()
      channel?.invokeMethod("screenCaptured", arguments: nil)
    } else {
      removePrivacyOverlay()
      channel?.invokeMethod("screenCaptureStopped", arguments: nil)
    }
  }

  private func showPrivacyOverlay() {
    guard protectionCount > 0 else { return }
    guard privacyOverlay == nil else { return }
    guard let window = window else { return }

    let overlay = UIView(frame: window.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.backgroundColor = UIColor(red: 0.067, green: 0.075, blue: 0.082, alpha: 1.0)
    overlay.isAccessibilityElement = true
    overlay.accessibilityLabel = "Screen capture is disabled"

    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 12
    stackView.translatesAutoresizingMaskIntoConstraints = false

    let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
    imageView.tintColor = .white
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = "Screen capture is disabled"
    titleLabel.textColor = .white
    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0

    let subtitleLabel = UILabel()
    subtitleLabel.text = "For your security, this content cannot be viewed while screen recording or mirroring is active."
    subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.72)
    subtitleLabel.font = .preferredFont(forTextStyle: .body)
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0

    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(subtitleLabel)
    overlay.addSubview(stackView)
    window.addSubview(overlay)

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 52),
      imageView.heightAnchor.constraint(equalToConstant: 52),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 28),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -28),
      stackView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
    ])

    privacyOverlay = overlay
  }

  private func removePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
