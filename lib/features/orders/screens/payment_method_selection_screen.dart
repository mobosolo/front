import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';
import 'package:front/core/config/kkiapay_config.dart';

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
  String? _lastPhoneInput;

  Future<void> _processPayment({String? phoneInput}) async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final response = await orderService.createOrder(
        basketId: widget.basketId,
        paymentMethod: _selectedPaymentMethod,
      );

      final orderId = response['order']['id'];

      if (mounted) {
        if (_selectedPaymentMethod == 'CASH') {
          context.pushReplacement('/order-confirmation/$orderId');
        } else {
          if (kkiapaySandbox) {
            await orderService.confirmPayment(orderId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paiement simule (sandbox).')),
            );
            context.pushReplacement('/order-confirmation/$orderId');
          } else {
            await _startKkiapay(orderId, phoneInput: phoneInput);
          }
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

  Future<void> _startKkiapay(String orderId, {String? phoneInput}) async {
    if (kkiapayPublicKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cle Kkiapay manquante.')),
      );
      return;
    }

    final user = ref.read(authStateProvider).user;
    String phone = (phoneInput ?? '').trim();
    if (phone.isEmpty) {
      phone = (user?.phoneNumber ?? '').trim();
    }
    List<String> countries = const ['TG'];
    if (kkiapaySandbox) {
      // Sandbox: force a documented test number with country code.
      phone = '22961000000';
      countries = const ['BJ'];
    } else if (phone.length == 8) {
      // Togo local number -> add country code.
      phone = '228$phone';
      countries = const ['TG'];
    }
    final name = user?.displayName ?? 'Client';
    final email = user?.email ?? '';

    void callback(dynamic response, BuildContext ctx) async {
      if (response is! Map) {
        return;
      }
      final Map<String, dynamic> data = Map<String, dynamic>.from(response);
      final String event = (data['status'] ?? data['name'] ?? data['event'] ?? '').toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KKiaPay event: $event')),
      );

      if (event == PAYMENT_SUCCESS) {
        final transactionId =
            data['transactionId']?.toString() ?? data['transaction_id']?.toString();
        try {
          await ref.read(orderServiceProvider).confirmPayment(
                orderId,
                transactionRef: transactionId,
              );
          if (!mounted) return;
          context.pushReplacement('/order-confirmation/$orderId');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paiement reussi mais confirmation impossible: ${e.toString()}')),
          );
        }
      } else if (event == PAYMENT_CANCELLED || event == CLOSE_WIDGET) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement annule ou ferme.')),
        );
      } else if (event == PAYMENT_INIT || event == PENDING_PAYMENT) {
        // Optional: ignore intermediate events.
        return;
      }
    }

    final kkiapay = KKiaPay(
      callback: callback,
      amount: widget.price,
      apikey: kkiapayPublicKey,
      sandbox: kkiapaySandbox,
      data: orderId,
      phone: phone,
      name: name,
      email: email,
      reason: 'Paiement panier ${widget.basketTitle ?? 'Panier'}',
      countries: countries,
      paymentMethods: const ['momo'],
      theme: kkiapayTheme,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => kkiapay),
    );
  }

  void _askPhoneThenPay() {
    final controller = TextEditingController(text: _lastPhoneInput ?? '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Paiement ${_selectedPaymentMethod == 'FLOOZ' ? 'Flooz' : 'Tmoney'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre numero pour le paiement.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Ex: 92430746'),
            ),
            if (kkiapaySandbox) ...[
              const SizedBox(height: 8),
              const Text(
                'Mode test: le paiement sera valide automatiquement.',
                style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _lastPhoneInput = controller.text.trim();
              Navigator.pop(ctx);
              _processPayment(phoneInput: _lastPhoneInput);
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
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
              onPressed: () {
                if (_selectedPaymentMethod == 'CASH') {
                  _processPayment();
                } else {
                  _askPhoneThenPay();
                }
              },
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
