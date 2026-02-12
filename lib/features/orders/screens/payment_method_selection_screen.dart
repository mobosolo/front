import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import
import 'package:front/features/orders/providers/order_providers.dart';

class PaymentMethodSelectionScreen extends ConsumerStatefulWidget {
  final String basketId;
  final int price;

  const PaymentMethodSelectionScreen({
    super.key,
    required this.basketId,
    required this.price,
  });

  @override
  ConsumerState<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends ConsumerState<PaymentMethodSelectionScreen> {
  String? _selectedPaymentMethod;
  bool _isLoading = false;

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une méthode de paiement.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final response = await orderService.createOrder(
        basketId: widget.basketId,
        paymentMethod: _selectedPaymentMethod!,
      );

      final orderId = response['order']['id'];
      final paymentUrl = response['paymentUrl'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande créée avec succès.')),
        );

        if (_selectedPaymentMethod == 'CASH') {
          context.pushReplacement('/order-confirmation/$orderId');
        } else if (paymentUrl != null) {
          // Launch the Flutterwave payment URL
          final Uri url = Uri.parse(paymentUrl);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
          // After launching the URL, navigate to the confirmation screen.
          // The backend webhook will update the payment status.
          context.pushReplacement('/order-confirmation/$orderId');
        } else {
          // Should not happen for mobile money, but good to have a fallback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune URL de paiement fournie.')),
          );
          context.pop(); // Go back
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création de la commande: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner Méthode de Paiement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Prix du panier: ${widget.price}€',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodTile('CASH', 'Paiement en espèces au commerçant', Icons.money),
            _buildPaymentMethodTile('FLOOZ', 'Mobile Money - Flooz', Icons.phone_android),
            _buildPaymentMethodTile('TMONEY', 'Mobile Money - TMoney', Icons.phone_iphone),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Confirmer la commande'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: RadioListTile<String>(
        title: Text(method),
        subtitle: Text(description),
        secondary: Icon(icon),
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (String? value) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
      ),
    );
  }
}
