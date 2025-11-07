import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase_service.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.loadProducts();
  }

  Future<void> _purchasePremium() async {
    setState(() => _isPurchasing = true);

    try {
      final success = await PurchaseService.purchasePremium();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase initiated')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);

    try {
      await PurchaseService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = PurchaseService.getPremiumProduct();
    final premiumAsync = ref.watch(premiumStatusProvider);
    final isPremium = premiumAsync.value ?? PurchaseService.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
      ),
      body: ListView(
        padding: AppTheme.responsivePadding(context),
        children: [
          const Icon(
            Icons.star,
            size: 80,
            color: AppTheme.joyfulColor,
          ),
          SizedBox(height: AppTheme.spacingL),
          const Text(
            'Premium: AI Dream Commentator',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingM),
          const Text(
            'Get AI-powered symbolic interpretations of your dreams',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),
          if (product != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkViolet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: AppTheme.spacingXL),
          if (isPremium)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'You are already a Premium member!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.joyfulColor,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            ElevatedButton(
              onPressed: _isPurchasing ? null : _purchasePremium,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkViolet,
                foregroundColor: AppTheme.offWhite,
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.offWhite),
                      ),
                    )
                  : const Text(
                      'Purchase Premium',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: AppTheme.spacingM),
            TextButton(
              onPressed: _isRestoring ? null : _restorePurchases,
              child: _isRestoring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Restore Purchases'),
            ),
          ],
        ],
      ),
    );
  }
}
