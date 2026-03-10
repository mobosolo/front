import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/core/theme/app_theme.dart';

class PaymentMethodSelectionScreen extends ConsumerStatefulWidget {
  final String basketId;
  final int price;
  final String? basketTitle;
  final String? merchantName;
  final String? pickupStart;
  final String? pickupEnd;

  const PaymentMethodSelectionScreen({
    super.key,
    required this.basketId,
    required this.price,
    this.basketTitle,
    this.merchantName,
    this.pickupStart,
    this.pickupEnd,
  });

  @override
  ConsumerState<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends ConsumerState<PaymentMethodSelectionScreen> {
  String _selectedPaymentMethod = 'FLOOZ';
  bool _isLoading = false;

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final response = await orderService.createOrder(
        basketId: widget.basketId,
        paymentMethod: _selectedPaymentMethod,
      );

      final orderId = response['order']['id'];
      final paymentUrl = response['paymentUrl'];

      if (mounted) {
        if (_selectedPaymentMethod == 'CASH') {
          context.pushReplacement('/order-confirmation/$orderId');
        } else if (paymentUrl != null) {
          final Uri url = Uri.parse(paymentUrl);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
          context.pushReplacement('/order-confirmation/$orderId');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune URL de paiement fournie.')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création de la commande: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: _LoadingSpinner(message: 'Traitement du paiement...')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                children: [
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _paymentMethodsCard(),
                ],
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Text('Paiement', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Résumé de la commande', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _summaryRow('Panier', widget.basketTitle ?? '—'),
          _summaryRow('Commerce', widget.merchantName ?? '—'),
          _summaryRow('Retrait', _pickupText()),
          const Divider(height: 24),
          _summaryRow('Total', '${widget.price} F', highlight: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: highlight ? AppTheme.primary : AppTheme.foreground),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Méthode de paiement', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _methodTile('FLOOZ', 'Flooz', Icons.credit_card),
          const SizedBox(height: 10),
          _methodTile('TMONEY', 'Tmoney', Icons.credit_card),
          const SizedBox(height: 10),
          _methodTile('CASH', 'Paiement au retrait', Icons.payments_outlined),
        ],
      ),
    );
  }

  Widget _methodTile(String value, String label, IconData icon) {
    final selected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : Colors.grey[300]!, width: 2),
          color: selected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppTheme.primary : Colors.grey[300]!, width: 2),
              ),
              child: selected
                  ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)))
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              child: const Text('Payer maintenant'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text('Annuler', style: TextStyle(color: AppTheme.mutedForeground)),
            ),
          ),
        ],
      ),
    );
  }

  String _pickupText() {
    if (widget.pickupStart == null || widget.pickupEnd == null) return '—';
    return '${widget.pickupStart} - ${widget.pickupEnd}';
  }
}

class _LoadingSpinner extends StatelessWidget {
  final String message;

  const _LoadingSpinner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
