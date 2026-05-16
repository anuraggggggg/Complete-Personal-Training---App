import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_storekit/src/store_kit_2_wrappers/sk2_transaction_wrapper.dart';

import '../extensions/shared_pref.dart';
import '../utils/app_constants.dart';

class IOSIapPurchaseResult {
  final String productId;
  final String transactionId;
  final String transactionDetail;

  IOSIapPurchaseResult({
    required this.productId,
    required this.transactionId,
    required this.transactionDetail,
  });
}

class IOSIapService {
  static const MethodChannel _appStoreReceiptChannel =
      MethodChannel('com.cpt.fitness/app_store_receipt');
  static const MethodChannel _appStoreIapChannel =
      MethodChannel('com.cpt.fitness/app_store_iap');
  static const String _getAppStoreReceiptMethod = 'getAppStoreReceipt';
  static const String _purchaseProductsMethod = 'purchaseProducts';
  static const Duration _productQueryTimeout = Duration(seconds: 15);
  static const Duration _purchaseLookupTimeout = Duration(seconds: 35);
  static const List<Duration> _productLookupRetryDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 700),
    Duration(milliseconds: 1500),
  ];
  static const Duration _sk2TransactionLookupWindow = Duration(seconds: 8);
  static final Map<String, ProductDetails> _cachedProductsById =
      <String, ProductDetails>{};

  IOSIapService({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  void _logIap(String message) {
    if (kDebugMode) {
      debugPrint('[IOS-IAP] $message');
    }
  }

  String _formatMissingProductsMessage(List<String> productIds) {
    final preview = productIds.take(4).join(', ');
    final suffix = productIds.length > 4 ? ', ...' : '';
    _logIap(
      'No matching App Store in-app purchase was found for this plan. '
      'Tried: $preview$suffix',
    );
    return 'We could not load this App Store subscription right now. '
        'Please try again in a moment or contact support if the issue continues.';
  }

  static const String _kAllVideoWorkoutProductId = 'com.cpt.fitness.12.months';

  static const Map<String, Map<int, List<String>>>
      _appleSubscriptionProductIds = <String, Map<int, List<String>>>{
    'both': <int, List<String>>{
      1: <String>['com.cpt.fitness.comboplan.1month'],
      3: <String>['com.cpt.fitness.comboplan.3month'],
      6: <String>['com.cpt.fitness.comboplan.6month'],
      12: <String>['com.cpt.fitness.comboplan.12month'],
      24: <String>['com.cpt.fitness.comboplan.24month'],
    },
    'workout': <int, List<String>>{
      1: <String>['com.cpt.fitness.workoutplan.1month'],
      3: <String>['com.cpt.fitness.workoutplan.3month'],
      6: <String>['com.cpt.fitness.workoutplan.6month'],
      12: <String>['com.cpt.fitness.workoutplan.12month'],
      24: <String>['com.cpt.fitness.workoutplan.24month'],
    },
    'diet': <int, List<String>>{
      1: <String>['com.cpt.fitness.diets.1month'],
    },
  };

  static const Map<String, Map<int, int>> _appleSubscriptionPrices =
      <String, Map<int, int>>{
    'both': <int, int>{
      1: 1499,
      3: 3549,
      6: 5999,
      12: 10999,
      24: 17500,
    },
    'workout': <int, int>{
      1: 1149,
      3: 3100,
      6: 5799,
      12: 10999,
      24: 17500,
    },
    'diet': <int, int>{
      1: 999,
    },
  };

  String _sanitizeProductId(String value) {
    return value
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }

  List<String> _sanitizeProductIds(Iterable<String>? values) {
    if (values == null) return const <String>[];
    return values
        .map(_sanitizeProductId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  Set<String> _allKnownCatalogProductIds() {
    final Set<String> ids = <String>{_kAllVideoWorkoutProductId};

    for (final MapEntry<String, Map<int, List<String>>> packageEntry
        in _appleSubscriptionProductIds.entries) {
      for (final MapEntry<int, List<String>> durationEntry
          in packageEntry.value.entries) {
        ids.addAll(durationEntry.value);
      }
    }

    return ids;
  }

  List<String> _fallbackProductIdsForPlan({
    String? packageType,
    String? planName,
    String? planDescription,
    int? duration,
    String? durationUnit,
  }) {
    final resolvedPackageType = _inferPackageType(
      packageType: packageType,
      planName: planName,
    );
    if (resolvedPackageType == null) return const <String>[];

    final durationInMonths = _normalizeDurationInMonths(
      duration: duration,
      durationUnit: durationUnit,
    );
    if (durationInMonths == null) return const <String>[];

    if (_isWorkoutAllVideoOnlyPlan(
      packageType: packageType,
      planName: planName,
      planDescription: planDescription,
      duration: duration,
      durationUnit: durationUnit,
    )) {
      return const <String>[_kAllVideoWorkoutProductId];
    }

    final mapped =
        _appleSubscriptionProductIds[resolvedPackageType]?[durationInMonths];
    return _sanitizeProductIds(mapped);
  }

  List<String> _validatedOverrideProductIds(
    List<String> overrideIds,
  ) {
    if (overrideIds.isEmpty) return const <String>[];

    final Set<String> exactCatalogIds = _allKnownCatalogProductIds();
    return overrideIds.where(exactCatalogIds.contains).toList();
  }

  void _cacheProducts(Iterable<ProductDetails> products) {
    for (final ProductDetails product in products) {
      final String normalizedId = _sanitizeProductId(product.id);
      if (normalizedId.isEmpty) continue;
      _cachedProductsById[normalizedId] = product;
    }
  }

  ProductDetails? _findCachedMatchingProduct(List<String> productIds) {
    for (final String productId in productIds) {
      final ProductDetails? cached = _cachedProductsById[productId];
      if (cached != null) {
        _logIap('Using cached App Store product: ${cached.id}');
        return cached;
      }
    }
    return null;
  }

  String _normalizeToken(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool _isWorkoutAllVideoOnlyPlan({
    String? packageType,
    String? planName,
    String? planDescription,
    int? duration,
    String? durationUnit,
  }) {
    final resolvedPackageType = _inferPackageType(
      packageType: packageType,
      planName: planName,
    );
    final durationInMonths = _normalizeDurationInMonths(
      duration: duration,
      durationUnit: durationUnit,
    );
    if (resolvedPackageType != 'workout' || durationInMonths != 12) {
      return false;
    }

    final normalizedDescription = _normalizeToken(planDescription ?? '');
    return normalizedDescription.contains('all_video_access_only') ||
        normalizedDescription.contains('video_access_only');
  }

  String? _normalizePackageType(String? packageType) {
    final normalized = _normalizeToken(packageType ?? '');
    if (normalized.isEmpty) return null;

    if (normalized == 'both' ||
        normalized == 'combo' ||
        normalized == 'diet_workout' ||
        normalized == 'workout_diet') {
      return 'both';
    }
    if (normalized.contains('workout')) return 'workout';
    if (normalized.contains('diet')) return 'diet';

    return null;
  }

  String? _inferPackageType({
    String? packageType,
    String? planName,
  }) {
    final explicitType = _normalizePackageType(packageType);
    if (explicitType != null) return explicitType;

    final normalizedName = _normalizeToken(planName ?? '');
    if (normalizedName.contains('combo') ||
        normalizedName.contains('both') ||
        (normalizedName.contains('diet') &&
            normalizedName.contains('workout'))) {
      return 'both';
    }
    if (normalizedName.contains('workout')) return 'workout';
    if (normalizedName.contains('diet')) return 'diet';

    return null;
  }

  int? _normalizeDurationInMonths({
    required int? duration,
    String? durationUnit,
  }) {
    final normalizedUnit = _normalizeToken(durationUnit ?? '');
    if (duration == null || duration <= 0) return null;

    if (normalizedUnit.isEmpty ||
        normalizedUnit == 'month' ||
        normalizedUnit == 'months' ||
        normalizedUnit == 'monthly') {
      return duration;
    }

    if (normalizedUnit == 'year' ||
        normalizedUnit == 'years' ||
        normalizedUnit == 'yearly' ||
        normalizedUnit == 'annual' ||
        normalizedUnit == 'annually') {
      return duration * 12;
    }

    return duration;
  }

  List<String> _resolveProductIds({
    String? packageType,
    String? planName,
    String? planDescription,
    int? duration,
    String? durationUnit,
    List<String>? productIdsOverride,
  }) {
    final fallbackIds = _fallbackProductIdsForPlan(
      packageType: packageType,
      planName: planName,
      planDescription: planDescription,
      duration: duration,
      durationUnit: durationUnit,
    );
    final overrideIds = _validatedOverrideProductIds(
      _sanitizeProductIds(productIdsOverride),
    );
    if (overrideIds.isNotEmpty) {
      final resolved = fallbackIds.isNotEmpty ? fallbackIds : overrideIds;
      _logIap(
        'Using exact iOS App Store product IDs: ${resolved.join(", ")}',
      );
      return resolved;
    }

    final resolvedPackageType = _inferPackageType(
      packageType: packageType,
      planName: planName,
    );
    if (resolvedPackageType == null) {
      throw Exception(
        'Unable to match this iOS subscription to an App Store product.',
      );
    }

    final durationInMonths = _normalizeDurationInMonths(
      duration: duration,
      durationUnit: durationUnit,
    );
    if (durationInMonths == null) {
      throw Exception(
        'Unable to determine the subscription duration for App Store purchase.',
      );
    }

    final productIds = fallbackIds;
    if (productIds.isEmpty) {
      throw Exception(
        'No App Store product is configured for $resolvedPackageType '
        '$durationInMonths month plan.',
      );
    }

    return _sanitizeProductIds(productIds);
  }

  int resolvePrice({
    required int fallbackPrice,
    String? packageType,
    String? planName,
    String? planDescription,
    int? duration,
    String? durationUnit,
  }) {
    if (_isWorkoutAllVideoOnlyPlan(
      packageType: packageType,
      planName: planName,
      planDescription: planDescription,
      duration: duration,
      durationUnit: durationUnit,
    )) {
      return 7400;
    }

    final resolvedPackageType = _inferPackageType(
      packageType: packageType,
      planName: planName,
    );
    final durationInMonths = _normalizeDurationInMonths(
      duration: duration,
      durationUnit: durationUnit,
    );

    return _appleSubscriptionPrices[resolvedPackageType]?[durationInMonths] ??
        fallbackPrice;
  }

  Future<Set<String>> fetchAvailableProductIds({
    Iterable<String>? extraProductIds,
  }) async {
    final products = await fetchAvailableProductsById(
      extraProductIds: extraProductIds,
    );
    return products.keys.toSet();
  }

  Future<Map<String, ProductDetails>> fetchAvailableProductsById({
    Iterable<String>? extraProductIds,
  }) async {
    if (!Platform.isIOS) return <String, ProductDetails>{};

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return <String, ProductDetails>{};

    final Set<String> allKnownProductIds = <String>{
      ..._allKnownCatalogProductIds(),
      ..._sanitizeProductIds(extraProductIds),
    };

    if (allKnownProductIds.isEmpty) {
      return <String, ProductDetails>{};
    }

    final List<String> orderedProductIds = allKnownProductIds.toList()..sort();
    final Map<String, ProductDetails> availableProducts =
        <String, ProductDetails>{};

    for (int attempt = 0;
        attempt < _productLookupRetryDelays.length;
        attempt++) {
      final Duration delay = _productLookupRetryDelays[attempt];
      if (delay > Duration.zero) {
        _logIap(
          'Retrying App Store catalog lookup '
          '(${attempt + 1}/${_productLookupRetryDelays.length}) after '
          '${delay.inMilliseconds}ms.',
        );
        await Future.delayed(delay);
      }

      for (final List<String> chunk in _chunkProductIds(orderedProductIds)) {
        try {
          final ProductDetailsResponse response = await _inAppPurchase
              .queryProductDetails(chunk.toSet())
              .timeout(_productQueryTimeout);
          _cacheProducts(response.productDetails);

          _logIap(
            'catalog query chunk [${chunk.join(", ")}] => '
            'found=${response.productDetails.map((e) => e.id).join(", ")} '
            '| notFound=${response.notFoundIDs.join(", ")}',
          );

          for (final ProductDetails item in response.productDetails) {
            availableProducts[item.id] = item;
          }
        } catch (e) {
          _logIap(
            'catalog query failed for [${chunk.join(", ")}]: $e',
          );
        }
      }

      if (availableProducts.isNotEmpty) {
        break;
      }
    }

    return availableProducts;
  }

  bool isSubscriptionAvailable({
    required Set<String> availableProductIds,
    String? packageType,
    String? planName,
    String? planDescription,
    int? duration,
    String? durationUnit,
    List<String>? productIdsOverride,
  }) {
    try {
      final List<String> productIds = _resolveProductIds(
        packageType: packageType,
        planName: planName,
        planDescription: planDescription,
        duration: duration,
        durationUnit: durationUnit,
        productIdsOverride: productIdsOverride,
      );

      return productIds.any(availableProductIds.contains);
    } catch (_) {
      return false;
    }
  }

  Future<ProductDetails?> _queryMatchingProducts(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return null;

    final ProductDetails? cachedMatch = _findCachedMatchingProduct(productIds);
    if (cachedMatch != null) {
      return cachedMatch;
    }

    _logIap('queryProductDetails request: ${productIds.join(", ")}');
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds.toSet()).timeout(
              _productQueryTimeout,
            );
    _cacheProducts(response.productDetails);

    _logIap(
      'queryProductDetails result: found=${response.productDetails.map((e) => e.id).join(", ")} '
      '| notFound=${response.notFoundIDs.join(", ")}',
    );

    if (response.productDetails.isEmpty) {
      return null;
    }

    for (final String productId in productIds) {
      for (final ProductDetails product in response.productDetails) {
        if (product.id == productId) {
          return product;
        }
      }
    }

    return response.productDetails.first;
  }

  Iterable<List<String>> _chunkProductIds(
    List<String> productIds, {
    int chunkSize = 12,
  }) sync* {
    for (int i = 0; i < productIds.length; i += chunkSize) {
      final int end = (i + chunkSize < productIds.length)
          ? i + chunkSize
          : productIds.length;
      yield productIds.sublist(i, end);
    }
  }

  Future<ProductDetails?> _findMatchingProduct(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return null;

    final ProductDetails? cachedMatch = _findCachedMatchingProduct(productIds);
    if (cachedMatch != null) {
      return cachedMatch;
    }

    final List<String> prioritizedIds = productIds.take(8).toList();
    final ProductDetails? preferredMatch =
        await _queryMatchingProducts(prioritizedIds);
    if (preferredMatch != null) {
      return preferredMatch;
    }

    if (productIds.length <= prioritizedIds.length) {
      return null;
    }

    final List<String> fallbackIds =
        productIds.skip(prioritizedIds.length).toList();
    for (final List<String> chunk in _chunkProductIds(fallbackIds)) {
      final ProductDetails? match = await _queryMatchingProducts(chunk);
      if (match != null) {
        return match;
      }
    }

    return null;
  }

  Future<ProductDetails?> _findMatchingProductWithRetry(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return null;

    for (int attempt = 0;
        attempt < _productLookupRetryDelays.length;
        attempt++) {
      final Duration delay = _productLookupRetryDelays[attempt];
      if (delay > Duration.zero) {
        _logIap(
          'Retrying App Store product lookup for ${productIds.join(", ")} '
          '(${attempt + 1}/${_productLookupRetryDelays.length}) after '
          '${delay.inMilliseconds}ms.',
        );
        await Future.delayed(delay);
      }

      ProductDetails? match;
      try {
        match = await _findMatchingProduct(productIds);
      } catch (e) {
        _logIap(
          'App Store product lookup failed for ${productIds.join(", ")}: $e',
        );
      }
      if (match != null) {
        return match;
      }

      if (attempt == 0) {
        final Map<String, ProductDetails> warmProducts =
            await fetchAvailableProductsById(
          extraProductIds: productIds,
        );
        ProductDetails? warmedMatch = _findCachedMatchingProduct(productIds);
        warmedMatch ??= () {
          for (final String productId in productIds) {
            final ProductDetails? product = warmProducts[productId];
            if (product != null) {
              return product;
            }
          }
          return null;
        }();
        if (warmedMatch != null) {
          return warmedMatch;
        }
      }
    }

    return null;
  }

  Future<String?> _fetchAppStoreReceipt() async {
    if (!Platform.isIOS) return null;

    try {
      final String? receipt =
          await _appStoreReceiptChannel.invokeMethod<String>(
        _getAppStoreReceiptMethod,
      );
      final String normalizedReceipt = receipt?.trim() ?? '';
      if (normalizedReceipt.isEmpty) {
        return null;
      }
      return normalizedReceipt;
    } catch (e) {
      _logIap('Failed to fetch App Store receipt: $e');
      return null;
    }
  }

  Future<IOSIapPurchaseResult?> _buySubscriptionViaNativeStoreKit({
    required List<String> productIds,
    required double maxAllowedPrice,
  }) async {
    if (!Platform.isIOS || productIds.isEmpty) {
      return null;
    }

    try {
      final Map<Object?, Object?>? response =
          await _appStoreIapChannel.invokeMapMethod<Object?, Object?>(
        _purchaseProductsMethod,
        <String, Object>{
          'productIds': productIds,
          'maxAllowedPrice': maxAllowedPrice,
        },
      );

      final String productId = response?['productId']?.toString().trim() ?? '';
      final String transactionId =
          response?['transactionId']?.toString().trim() ?? '';
      final String transactionDetail =
          response?['transactionDetail']?.toString().trim() ?? '';

      if (productId.isEmpty ||
          transactionId.isEmpty ||
          transactionDetail.isEmpty) {
        return null;
      }

      await setValue(IS_IN_APP_PURCHASED, true);

      return IOSIapPurchaseResult(
        productId: productId,
        transactionId: transactionId,
        transactionDetail: transactionDetail,
      );
    } on PlatformException catch (e) {
      _logIap(
        'Native StoreKit purchase fallback failed: '
        '${e.code} | ${e.message} | ${e.details}',
      );

      final String message = e.message?.trim() ?? '';
      if (message.isNotEmpty) {
        throw Exception(message);
      }
      rethrow;
    } catch (e) {
      _logIap('Native StoreKit purchase fallback failed: $e');
      rethrow;
    }
  }

  Future<String?> fetchCurrentAppStoreReceipt() => _fetchAppStoreReceipt();

  Future<void> restorePurchases() async {
    if (!Platform.isIOS) return;
    await _inAppPurchase.restorePurchases();
  }

  DateTime? _parseStoreKitPurchaseDate(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;

    return DateTime.tryParse(
      normalized.contains(' ') ? normalized.replaceFirst(' ', 'T') : normalized,
    );
  }

  Future<SK2Transaction?> _findMatchingUnfinishedSk2Transaction({
    required String productId,
    required DateTime purchaseAttemptStartedAt,
  }) async {
    try {
      final List<SK2Transaction> unfinishedTransactions =
          await SK2Transaction.unfinishedTransactions();
      if (unfinishedTransactions.isEmpty) return null;

      final DateTime earliestAcceptedPurchase =
          purchaseAttemptStartedAt.subtract(_sk2TransactionLookupWindow);

      final List<SK2Transaction> matches = unfinishedTransactions.where((
        SK2Transaction transaction,
      ) {
        if (transaction.productId != productId) return false;

        final DateTime? purchaseDate =
            _parseStoreKitPurchaseDate(transaction.purchaseDate);
        if (purchaseDate == null) return true;

        return !purchaseDate.isBefore(earliestAcceptedPurchase);
      }).toList()
        ..sort((SK2Transaction a, SK2Transaction b) {
          final DateTime aDate = _parseStoreKitPurchaseDate(a.purchaseDate) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bDate = _parseStoreKitPurchaseDate(b.purchaseDate) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      if (matches.isEmpty) {
        _logIap(
          'No matching unfinished StoreKit 2 transaction found for $productId.',
        );
        return null;
      }

      final SK2Transaction resolved = matches.first;
      _logIap(
        'Resolved StoreKit 2 transaction for $productId via unfinished queue: '
        'id=${resolved.id}, purchaseDate=${resolved.purchaseDate}',
      );
      return resolved;
    } catch (e) {
      _logIap('Unable to inspect unfinished StoreKit 2 transactions: $e');
      return null;
    }
  }

  Future<void> _completePendingPurchaseSafely(PurchaseDetails purchase,
      {String? resolvedTransactionId}) async {
    if (!purchase.pendingCompletePurchase) return;

    final bool isStoreKit2Purchase = purchase is SK2PurchaseDetails;
    final String purchaseId =
        purchase.purchaseID?.trim() ?? resolvedTransactionId?.trim() ?? '';

    if (isStoreKit2Purchase && purchaseId.isEmpty) {
      _logIap(
        'Skipping completePurchase for ${purchase.productID} because StoreKit 2 purchaseID is still empty.',
      );
      return;
    }

    try {
      if (isStoreKit2Purchase && purchase.purchaseID?.trim().isEmpty == true) {
        await SK2Transaction.finish(int.parse(purchaseId));
        return;
      }
      await _inAppPurchase.completePurchase(purchase);
    } catch (e) {
      _logIap(
        'completePurchase failed for ${purchase.productID} '
        '(${purchase.purchaseID ?? resolvedTransactionId}): $e',
      );
    }
  }

  Future<IOSIapPurchaseResult> buySubscription({
    required double backendPrice,
    String? packageType,
    String? planName,
    String? planDescription,
    int? duration,
    String? durationUnit,
    List<String>? productIdsOverride,
  }) async {
    if (!Platform.isIOS) {
      throw Exception('In-App Purchase is available only on iOS.');
    }

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('In-App Purchase is not available on this device.');
    }

    final List<String> productIds = _resolveProductIds(
      packageType: packageType,
      planName: planName,
      planDescription: planDescription,
      duration: duration,
      durationUnit: durationUnit,
      productIdsOverride: productIdsOverride,
    );
    final double maxAllowedPrice = backendPrice * 1.15;
    _logIap(
      'Resolved IDs for plan '
      '[packageType=$packageType, planName=$planName, duration=$duration, durationUnit=$durationUnit]: '
      '${productIds.join(", ")}',
    );
    final ProductDetails? product = await _findMatchingProductWithRetry(
      productIds,
    ).timeout(_purchaseLookupTimeout, onTimeout: () => null);

    if (product == null) {
      final IOSIapPurchaseResult? nativePurchase =
          await _buySubscriptionViaNativeStoreKit(
        productIds: productIds,
        maxAllowedPrice: maxAllowedPrice,
      );
      if (nativePurchase != null) {
        return nativePurchase;
      }
      throw Exception(_formatMissingProductsMessage(productIds));
    }
    _logIap(
      'Matched product: ${product.id} | rawPrice=${product.rawPrice} | currency=${product.currencyCode}',
    );
    final String productId = product.id;
    if (product.rawPrice > maxAllowedPrice + 0.001) {
      throw Exception(
        'IAP price exceeds the 15% commission limit for this plan.',
      );
    }

    final Completer<IOSIapPurchaseResult> completer =
        Completer<IOSIapPurchaseResult>();
    final DateTime purchaseAttemptStartedAt = DateTime.now();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchases) async {
        for (final PurchaseDetails purchase in purchases) {
          if (purchase.productID != productId) continue;

          try {
            if (purchase.status == PurchaseStatus.pending) continue;

            if (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored) {
              String resolvedTransactionId = purchase.purchaseID?.trim() ?? '';
              String originalTransactionId = resolvedTransactionId;
              String resolvedTransactionDate =
                  purchase.transactionDate?.trim() ?? '';
              String storeKitServerVerificationData =
                  purchase.verificationData.serverVerificationData;
              String storeKitLocalVerificationData =
                  purchase.verificationData.localVerificationData;

              if (purchase is SK2PurchaseDetails &&
                  resolvedTransactionId.isEmpty) {
                final SK2Transaction? resolvedTransaction =
                    await _findMatchingUnfinishedSk2Transaction(
                  productId: purchase.productID,
                  purchaseAttemptStartedAt: purchaseAttemptStartedAt,
                );

                if (resolvedTransaction == null) {
                  _logIap(
                    'StoreKit 2 purchase for ${purchase.productID} is still waiting for a transaction ID. '
                    'Keeping the listener alive for the next callback.',
                  );
                  continue;
                }

                resolvedTransactionId = resolvedTransaction.id.toString();
                originalTransactionId =
                    resolvedTransaction.originalId.trim().isEmpty
                        ? resolvedTransactionId
                        : resolvedTransaction.originalId.trim();
                resolvedTransactionDate = resolvedTransaction.purchaseDate;

                final String resolvedReceiptData =
                    resolvedTransaction.receiptData?.trim() ?? '';
                final String resolvedJsonRepresentation =
                    resolvedTransaction.jsonRepresentation?.trim() ?? '';

                if (resolvedReceiptData.isNotEmpty) {
                  storeKitServerVerificationData = resolvedReceiptData;
                }
                if (resolvedJsonRepresentation.isNotEmpty) {
                  storeKitLocalVerificationData = resolvedJsonRepresentation;
                }
              }

              if (purchase is AppStorePurchaseDetails) {
                final String sk1OriginalTransactionId = purchase
                        .skPaymentTransaction
                        .originalTransaction
                        ?.transactionIdentifier
                        ?.trim() ??
                    '';
                if (sk1OriginalTransactionId.isNotEmpty) {
                  originalTransactionId = sk1OriginalTransactionId;
                }
              }

              if (resolvedTransactionId.isEmpty) {
                _logIap(
                  'Ignoring purchased callback for ${purchase.productID} because no transaction ID is available yet.',
                );
                continue;
              }

              await setValue(IS_IN_APP_PURCHASED, true);

              final String? appStoreReceipt = await _fetchAppStoreReceipt();
              final String effectiveReceiptData =
                  appStoreReceipt?.isNotEmpty == true
                      ? appStoreReceipt!
                      : storeKitServerVerificationData;

              if (!completer.isCompleted) {
                completer.complete(
                  IOSIapPurchaseResult(
                    productId: productId,
                    transactionId: resolvedTransactionId,
                    transactionDetail: jsonEncode({
                      'source': 'app_store_iap',
                      'product_id': productId,
                      'purchase_id': resolvedTransactionId,
                      'transaction_id': resolvedTransactionId,
                      'original_transaction_id': originalTransactionId,
                      'status': purchase.status.name,
                      'transaction_date': resolvedTransactionDate,
                      'server_verification_data': effectiveReceiptData,
                      'local_verification_data': storeKitLocalVerificationData,
                      if (appStoreReceipt?.isNotEmpty == true)
                        'app_store_receipt': appStoreReceipt,
                      if (appStoreReceipt?.isNotEmpty == true)
                        'receipt_data': appStoreReceipt,
                      if (storeKitServerVerificationData.isNotEmpty)
                        'storekit_server_verification_data':
                            storeKitServerVerificationData,
                      if (storeKitLocalVerificationData.isNotEmpty)
                        'storekit_local_verification_data':
                            storeKitLocalVerificationData,
                    }),
                  ),
                );
              }

              await _completePendingPurchaseSafely(
                purchase,
                resolvedTransactionId: resolvedTransactionId,
              );
            } else if (purchase.status == PurchaseStatus.error ||
                purchase.status == PurchaseStatus.canceled) {
              if (!completer.isCompleted) {
                completer.completeError(
                  Exception(
                    purchase.error?.message ??
                        'In-App Purchase was cancelled or failed.',
                  ),
                );
              }

              await _completePendingPurchaseSafely(purchase);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(
                Exception(
                  'Unable to complete the App Store purchase. Please try again.',
                ),
              );
            }
            _logIap('purchaseStream handling failed: $e');
          }
        }
      },
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    final bool launched = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!launched) {
      await subscription.cancel();
      throw Exception('Unable to start In-App Purchase.');
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception('In-App Purchase timed out. Please try again.');
        },
      );
    } finally {
      await subscription.cancel();
    }
  }
}
