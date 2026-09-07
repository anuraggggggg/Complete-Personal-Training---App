import Flutter
import StoreKit
import UIKit

private struct AppStoreBridgeError: Error {
  let code: String
  let message: String
  let details: Any?

  init(code: String, message: String, details: Any? = nil) {
    self.code = code
    self.message = message
    self.details = details
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, SKRequestDelegate {
  private let appStoreReceiptChannelName = "com.cpt.fitness/app_store_receipt"
  private let appStoreIapChannelName = "com.cpt.fitness/app_store_iap"
  private let getAppStoreReceiptMethod = "getAppStoreReceipt"
  private let purchaseProductsMethod = "purchaseProducts"
  private let queryProductsMethod = "queryProducts"

  private var appStoreReceiptChannel: FlutterMethodChannel?
  private var appStoreIapChannel: FlutterMethodChannel?
  private var screenSecurityManager: ScreenSecurityManager?
  private var receiptRefreshRequest: SKReceiptRefreshRequest?
  private var receiptRefreshCompletions: [(Result<String, Error>) -> Void] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      setupAppStoreReceiptChannel(binaryMessenger: controller.binaryMessenger)
      setupAppStoreIapChannel(binaryMessenger: controller.binaryMessenger)
      setupScreenSecurityChannel(binaryMessenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    setupAppStoreReceiptChannel(binaryMessenger: messenger)
    setupAppStoreIapChannel(binaryMessenger: messenger)
    setupScreenSecurityChannel(binaryMessenger: messenger)
  }

  private func setupScreenSecurityChannel(
    binaryMessenger: FlutterBinaryMessenger
  ) {
    screenSecurityManager = ScreenSecurityManager(
      window: window,
      binaryMessenger: binaryMessenger
    )
  }

  private func setupAppStoreReceiptChannel(
    binaryMessenger: FlutterBinaryMessenger
  ) {
    let channel = FlutterMethodChannel(
      name: appStoreReceiptChannelName,
      binaryMessenger: binaryMessenger
    )
    appStoreReceiptChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(
          FlutterError(
            code: "app_delegate_unavailable",
            message: "AppDelegate was released before receipt handling completed.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case self.getAppStoreReceiptMethod:
        self.handleAppStoreReceiptRequest(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupAppStoreIapChannel(
    binaryMessenger: FlutterBinaryMessenger
  ) {
    let channel = FlutterMethodChannel(
      name: appStoreIapChannelName,
      binaryMessenger: binaryMessenger
    )
    appStoreIapChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(
          FlutterError(
            code: "app_delegate_unavailable",
            message: "AppDelegate was released before App Store purchase handling completed.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case self.queryProductsMethod:
        self.handleQueryProducts(call: call, result: result)
      case self.purchaseProductsMethod:
        self.handlePurchaseProducts(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleAppStoreReceiptRequest(result: @escaping FlutterResult) {
    refreshAppStoreReceipt { [weak self] refreshResult in
      guard let self = self else {
        result(
          FlutterError(
            code: "app_delegate_unavailable",
            message: "AppDelegate was released before receipt handling completed.",
            details: nil
          )
        )
        return
      }

      switch refreshResult {
      case .success(let receipt):
        result(receipt)
      case .failure(let error):
        result(
          self.flutterError(
            from: error,
            defaultCode: "receipt_unavailable",
            defaultMessage: "App Store receipt is unavailable."
          )
        )
      }
    }
  }

  private func refreshAppStoreReceipt(
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    if let receipt = readAppStoreReceipt() {
      completion(.success(receipt))
      return
    }

    receiptRefreshCompletions.append(completion)
    if receiptRefreshRequest != nil {
      return
    }

    let request = SKReceiptRefreshRequest()
    receiptRefreshRequest = request
    request.delegate = self
    request.start()
  }

  private func completeReceiptRefresh(with outcome: Result<String, Error>) {
    let completions = receiptRefreshCompletions
    receiptRefreshCompletions.removeAll()
    receiptRefreshRequest = nil

    completions.forEach { completion in
      completion(outcome)
    }
  }

  private func readAppStoreReceipt() -> String? {
    guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
      return nil
    }

    guard FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
      return nil
    }

    do {
      let receiptData = try Data(contentsOf: appStoreReceiptURL)
      guard !receiptData.isEmpty else {
        return nil
      }
      return receiptData.base64EncodedString(options: [])
    } catch {
      NSLog("Failed to read App Store receipt: \(error.localizedDescription)")
      return nil
    }
  }

  private func sanitizeProductIds(from arguments: Any?) -> [String]? {
    guard
      let payload = arguments as? [String: Any],
      let rawProductIds = payload["productIds"] as? [String]
    else {
      return nil
    }

    var uniqueIds = Set<String>()
    var orderedIds: [String] = []

    for rawId in rawProductIds {
      let normalizedId = rawId
        .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)

      guard !normalizedId.isEmpty else { continue }
      if uniqueIds.insert(normalizedId).inserted {
        orderedIds.append(normalizedId)
      }
    }

    return orderedIds.isEmpty ? nil : orderedIds
  }

  private func handleQueryProducts(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let productIds = sanitizeProductIds(from: call.arguments) else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "A non-empty productIds array is required.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 15.0, *) else {
      result(
        FlutterError(
          code: "storekit_unavailable",
          message: "StoreKit 2 requires iOS 15 or later.",
          details: nil
        )
      )
      return
    }

    Task { @MainActor [weak self] in
      guard let self = self else {
        result(
          FlutterError(
            code: "app_delegate_unavailable",
            message: "AppDelegate was released before App Store product lookup completed.",
            details: nil
          )
        )
        return
      }

      do {
        result(try await self.queryProducts(productIds: productIds))
      } catch {
        result(
          self.flutterError(
            from: error,
            defaultCode: "app_store_query_failed",
            defaultMessage: "Unable to query App Store products."
          )
        )
      }
    }
  }

  private func handlePurchaseProducts(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let productIds = sanitizeProductIds(from: call.arguments) else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "A non-empty productIds array is required.",
          details: nil
        )
      )
      return
    }

    let maxAllowedPrice = ((call.arguments as? [String: Any])?["maxAllowedPrice"] as? NSNumber)?
      .doubleValue

    guard #available(iOS 15.0, *) else {
      result(
        FlutterError(
          code: "storekit_unavailable",
          message: "StoreKit 2 requires iOS 15 or later.",
          details: nil
        )
      )
      return
    }

    Task { @MainActor [weak self] in
      guard let self = self else {
        result(
          FlutterError(
            code: "app_delegate_unavailable",
            message: "AppDelegate was released before App Store purchase completed.",
            details: nil
          )
        )
        return
      }

      do {
        result(
          try await self.purchaseProducts(
            productIds: productIds,
            maxAllowedPrice: maxAllowedPrice
          )
        )
      } catch {
        result(
          self.flutterError(
            from: error,
            defaultCode: "app_store_purchase_failed",
            defaultMessage: "Unable to complete the App Store purchase."
          )
        )
      }
    }
  }

  @available(iOS 15.0, *)
  private func queryProducts(productIds: [String]) async throws -> [[String: Any]] {
    let products = try await Product.products(for: productIds)
    let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

    if productMap.isEmpty {
      throw AppStoreBridgeError(
        code: "app_store_products_not_found",
        message: "App Store did not return any products for this app. Verify the iOS bundle identifier and App Store product IDs in App Store Connect.",
        details: ["productIds": productIds]
      )
    }

    return productIds.compactMap { productId in
      guard let product = productMap[productId] else { return nil }
      return [
        "id": product.id,
        "displayPrice": product.displayPrice,
        "price": NSDecimalNumber(decimal: product.price).doubleValue,
      ]
    }
  }

  @available(iOS 15.0, *)
  private func purchaseProducts(
    productIds: [String],
    maxAllowedPrice: Double?
  ) async throws -> [String: Any] {
    let products = try await Product.products(for: productIds)
    let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

    guard
      let selectedProduct = productIds.compactMap({ productMap[$0] }).first ?? products.first
    else {
      throw AppStoreBridgeError(
        code: "app_store_products_not_found",
        message: "App Store did not return any products for this app. Verify the iOS bundle identifier and App Store product IDs in App Store Connect.",
        details: ["productIds": productIds]
      )
    }

    let rawPrice = NSDecimalNumber(decimal: selectedProduct.price).doubleValue
    if let maxAllowedPrice, rawPrice > maxAllowedPrice + 0.001 {
      throw AppStoreBridgeError(
        code: "app_store_price_limit_exceeded",
        message: "App Store price exceeds the allowed price for this plan.",
        details: [
          "productId": selectedProduct.id,
          "price": rawPrice,
          "maxAllowedPrice": maxAllowedPrice,
        ]
      )
    }

    let purchaseResult = try await selectedProduct.purchase()

    switch purchaseResult {
    case .pending:
      throw AppStoreBridgeError(
        code: "app_store_purchase_pending",
        message: "The App Store purchase is pending approval.",
        details: ["productId": selectedProduct.id]
      )
    case .userCancelled:
      throw AppStoreBridgeError(
        code: "app_store_user_cancelled",
        message: "The App Store purchase was cancelled.",
        details: ["productId": selectedProduct.id]
      )
    case .success(let verificationResult):
      let transaction = try verifiedTransaction(from: verificationResult)
      let signedTransaction = verificationResult.jwsRepresentation
      let receipt = try await fetchAppStoreReceipt()
      let transactionDate = ISO8601DateFormatter().string(from: transaction.purchaseDate)
      let transactionId = String(transaction.id)
      let originalTransactionId = String(transaction.originalID)

      let transactionDetailPayload: [String: Any] = [
        "source": "native_storekit2",
        "product_id": transaction.productID,
        "purchase_id": transactionId,
        "transaction_id": transactionId,
        "original_transaction_id": originalTransactionId,
        "status": "purchased",
        "transaction_date": transactionDate,
        "signed_transaction": signedTransaction,
        "jws_representation": signedTransaction,
        "server_verification_data": receipt,
        "local_verification_data": "",
        "app_store_receipt": receipt,
        "receipt_data": receipt,
      ]

      let transactionDetail = try jsonString(from: transactionDetailPayload)
      await transaction.finish()

      return [
        "productId": transaction.productID,
        "transactionId": transactionId,
        "transactionDetail": transactionDetail,
        "price": rawPrice,
      ]
    @unknown default:
      throw AppStoreBridgeError(
        code: "app_store_purchase_unknown",
        message: "Received an unknown App Store purchase state.",
        details: ["productId": selectedProduct.id]
      )
    }
  }

  @available(iOS 15.0, *)
  private func verifiedTransaction(
    from verificationResult: VerificationResult<Transaction>
  ) throws -> Transaction {
    switch verificationResult {
    case .verified(let transaction):
      return transaction
    case .unverified(_, let verificationError):
      throw AppStoreBridgeError(
        code: "app_store_purchase_unverified",
        message: "App Store could not verify the transaction.",
        details: ["error": verificationError.localizedDescription]
      )
    }
  }

  private func fetchAppStoreReceipt() async throws -> String {
    if let receipt = readAppStoreReceipt() {
      return receipt
    }

    return try await withCheckedThrowingContinuation { continuation in
      refreshAppStoreReceipt { result in
        continuation.resume(with: result)
      }
    }
  }

  private func jsonString(from payload: [String: Any]) throws -> String {
    do {
      let data = try JSONSerialization.data(withJSONObject: payload, options: [])
      guard let jsonString = String(data: data, encoding: .utf8) else {
        throw AppStoreBridgeError(
          code: "transaction_detail_encoding_failed",
          message: "Unable to encode transaction details for the App Store purchase."
        )
      }
      return jsonString
    } catch let bridgeError as AppStoreBridgeError {
      throw bridgeError
    } catch {
      throw AppStoreBridgeError(
        code: "transaction_detail_encoding_failed",
        message: "Unable to encode transaction details for the App Store purchase.",
        details: ["error": error.localizedDescription]
      )
    }
  }

  private func flutterError(
    from error: Error,
    defaultCode: String,
    defaultMessage: String
  ) -> FlutterError {
    if let bridgeError = error as? AppStoreBridgeError {
      return FlutterError(
        code: bridgeError.code,
        message: bridgeError.message,
        details: bridgeError.details
      )
    }

    return FlutterError(
      code: defaultCode,
      message: error.localizedDescription.isEmpty ? defaultMessage : error.localizedDescription,
      details: nil
    )
  }

  func requestDidFinish(_ request: SKRequest) {
    guard request === receiptRefreshRequest else { return }

    guard let receipt = readAppStoreReceipt() else {
      completeReceiptRefresh(
        with: .failure(
          AppStoreBridgeError(
            code: "receipt_unavailable",
            message: "App Store receipt is unavailable after refresh.",
            details: nil
          )
        )
      )
      return
    }

    completeReceiptRefresh(with: .success(receipt))
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    guard request === receiptRefreshRequest else { return }
    completeReceiptRefresh(with: .failure(error))
  }
}
