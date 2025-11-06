import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_boxes.dart';

class PurchaseService {
  static const String _premiumProductId = 'premium_ai_commentator';
  static final InAppPurchase _iap = InAppPurchase.instance;
  static final StreamController<bool> _premiumController =
      StreamController<bool>.broadcast();

  static Stream<bool> get premiumStream => _premiumController.stream;
  static bool _isPremium = false;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];

  static Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      _premiumController.add(false);
      return;
    }

    // Load cached premium status
    await _loadPremiumStatus();

    // Listen to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    purchaseUpdated.listen(
      _handlePurchaseUpdate,
      onDone: () => _premiumController.close(),
      onError: (error) => _premiumController.addError(error),
    );

    // Load products
    await loadProducts();

    // Restore purchases on init
    await restorePurchases();
  }

  static Future<void> _loadPremiumStatus() async {
    try {
      final prefsBox = await Hive.openBox(HiveBoxes.preferences);
      _isPremium = prefsBox.get('is_premium', defaultValue: false) as bool;
      _premiumController.add(_isPremium);
    } catch (e) {
      _isPremium = false;
      _premiumController.add(false);
    }
  }

  static Future<void> _savePremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    final prefsBox = await Hive.openBox(HiveBoxes.preferences);
    await prefsBox.put('is_premium', isPremium);
    _premiumController.add(isPremium);
  }

  static Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final productIds = <String>{_premiumProductId};
    final response = await _iap.queryProductDetails(productIds);

    if (response.error != null) {
      return;
    }

    _products = response.productDetails;
  }

  static ProductDetails? getPremiumProduct() {
    return _products.firstWhere(
      (product) => product.id == _premiumProductId,
      orElse: () => _products.first,
    );
  }

  static bool get isPremium => _isPremium;

  static Future<bool> purchasePremium() async {
    if (!_isAvailable || _products.isEmpty) {
      return false;
    }

    final product = getPremiumProduct();
    if (product == null) return false;

    final purchaseParam = PurchaseParam(productDetails: product);
    final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    return success;
  }

  static Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    await _iap.restorePurchases();
  }

  static Future<void> _handlePurchaseUpdate(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify purchase
          if (purchaseDetails.productID == _premiumProductId) {
            await _savePremiumStatus(true);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  static void dispose() {
    _premiumController.close();
  }
}
