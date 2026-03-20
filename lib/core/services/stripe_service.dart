import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  // REMPLACE PAR TA CLÉ SECRÈTE sk_test_... (Dashboard Stripe)
  

  static Future<void> initPayment(String amount, BuildContext context) async {
    try {
      // 1. Créer le Payment Intent
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'amount': amount, 
          'currency': 'eur', 
        },
      );

      final jsonResponse = jsonDecode(response.body);

      // 2. Initialiser la feuille de paiement
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['client_secret'],
          merchantDisplayName: 'MealFlavor',
          style: ThemeMode.light,
        ),
      );

      // 3. Afficher la feuille
      await Stripe.instance.presentPaymentSheet();

    } catch (e) {
      // Si l'utilisateur annule, Stripe jette une exception, on la gère ici
      debugPrint("Erreur ou annulation : $e");
      rethrow; // On renvoie l'erreur pour que la page de paiement sache qu'il faut arrêter le chargement
    }
  }
}