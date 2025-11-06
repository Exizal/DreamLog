import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase_service.dart';

final premiumStatusProvider = StreamProvider<bool>((ref) {
  return PurchaseService.premiumStream;
});

