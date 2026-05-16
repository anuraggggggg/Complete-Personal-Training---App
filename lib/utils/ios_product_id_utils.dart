String _normalizeProductKey(String key) {
  return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

bool _looksLikeAppStoreProductId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return false;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return false;
  }
  if (normalized.contains(' ')) return false;
  if (!normalized.contains('.')) return false;

  return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(normalized) &&
      RegExp(r'[A-Za-z]').hasMatch(normalized);
}

bool _isLikelyProductIdKey(String normalizedKey) {
  const directKeys = <String>{
    'productid',
    'productids',
    'subscriptionproductid',
    'subscriptionproductids',
    'subscriptionproductidentifier',
    'subscriptionproductidentifiers',
    'iosproductid',
    'iosproductids',
    'iosproductidentifier',
    'iosproductidentifiers',
    'iossubscriptionid',
    'iossubscriptionids',
    'appleproductid',
    'appleproductids',
    'appleproductidentifier',
    'appleproductidentifiers',
    'appstoreproductid',
    'appstoreproductids',
    'storeproductid',
    'storeproductids',
    'storekitproductid',
    'storekitproductids',
    'productidios',
    'productidsios',
    'inappproductid',
    'inappproductids',
    'inapppurchaseproductid',
    'inapppurchaseproductids',
    'iosinappproductid',
    'iosinappproductids',
    'applesubscriptionproductid',
    'applesubscriptionproductids',
  };

  if (directKeys.contains(normalizedKey)) return true;

  final hasProductMarker = normalizedKey.contains('product') ||
      normalizedKey.contains('identifier') ||
      normalizedKey.contains('subscription');
  final hasPlatformMarker = normalizedKey.contains('ios') ||
      normalizedKey.contains('apple') ||
      normalizedKey.contains('appstore') ||
      normalizedKey.contains('storekit') ||
      normalizedKey.contains('store') ||
      normalizedKey.contains('inapp');

  return hasProductMarker && hasPlatformMarker;
}

bool _isLikelyProductContainerKey(String normalizedKey) {
  const containerKeys = <String>{
    'ios',
    'apple',
    'appstore',
    'appstoreconnect',
    'storekit',
    'inapp',
    'inapppurchase',
    'iosproducts',
    'appleproducts',
    'appstoreproducts',
    'storeproducts',
    'storekitproducts',
    'subscriptionproducts',
    'inappproducts',
    'iosinappproducts',
  };

  if (containerKeys.contains(normalizedKey)) return true;

  return (normalizedKey.contains('products') ||
          normalizedKey.contains('identifiers')) &&
      (normalizedKey.contains('ios') ||
          normalizedKey.contains('apple') ||
          normalizedKey.contains('store') ||
          normalizedKey.contains('inapp') ||
          normalizedKey.contains('subscription'));
}

List<String>? extractIosProductIds(Map<String, dynamic> json) {
  final values = <String>{};

  void collectString(String rawValue, List<String> path) {
    if (!path.any(_isLikelyProductIdKey) &&
        !path.any(_isLikelyProductContainerKey)) {
      return;
    }

    for (final candidate in rawValue
        .split(RegExp(r'[,;\n|]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)) {
      if (_looksLikeAppStoreProductId(candidate)) {
        values.add(candidate);
      }
    }
  }

  void walk(dynamic node, List<String> path) {
    if (node == null) return;

    if (node is String) {
      collectString(node, path);
      return;
    }

    if (node is List) {
      for (final child in node) {
        walk(child, path);
      }
      return;
    }

    if (node is Map) {
      final mapped = node.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      for (final entry in mapped.entries) {
        final normalizedKey = _normalizeProductKey(entry.key);
        final nextPath = <String>[...path, normalizedKey];
        final child = entry.value;

        if (child is String || child is List || child is Map) {
          walk(child, nextPath);
        }
      }
    }
  }

  walk(json, const <String>[]);

  if (values.isEmpty) return null;
  return values.toList();
}
