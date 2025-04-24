import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> payWithStripe({
  required double amount,
  required BuildContext context,
  required VoidCallback onSuccess,
}) async {
  try {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
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
      const SnackBar(
        content: Text("Paiement réussi ✅"),
        backgroundColor: Colors.green,
      ),
    );

    onSuccess();

  } catch (e) {
    print("Erreur Stripe : $e");
    
    String errorMessage;
    if (e is StripeException) {
      switch (e.error.code) {
        case FailureCode.Canceled:
          errorMessage = "Le paiement a été annulé. Vous pouvez réessayer si vous le souhaitez.";
          break;
        case FailureCode.Failed:
          errorMessage = "Le paiement a échoué. Veuillez vérifier vos informations de paiement.";
          break;
        case FailureCode.Timeout:
          errorMessage = "Le paiement a expiré. Veuillez réessayer.";
          break;
        default:
          errorMessage = "Une erreur est survenue lors du paiement. Veuillez réessayer.";
      }
    } else {
      errorMessage = "Une erreur inattendue est survenue. Veuillez réessayer.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
