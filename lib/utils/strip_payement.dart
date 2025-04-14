import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> payWithStripe({
  required double amount,
  required BuildContext context,
  required VoidCallback onSuccess,
}) async {
  try {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('initStripePayment');

final result = await callable.call({'amount': amount});
final clientSecret = result.data['clientSecret'];

await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    paymentIntentClientSecret: clientSecret,
    merchantDisplayName: 'Chronocourse',
  ),
);

await Stripe.instance.presentPaymentSheet();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Paiement réussi ✅")),
    );

    onSuccess(); // exécute ton callback de traitement de commande

  } catch (e) {
    print("Erreur Stripe : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur de paiement : $e")),
    );
  }
}
