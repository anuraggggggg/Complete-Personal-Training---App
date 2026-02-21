import 'package:razorpay_flutter/razorpay_flutter.dart';


class RazorpayService {
  late Razorpay _razorpay;

  /// ✅ LIVE KEY ID ONLY (SAFE)
  static const String liveKey = "rzp_live_RsCjRLal1MjiQT";

  void init({
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) {
    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse response) {
        onSuccess(response.paymentId!);
      },
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      (PaymentFailureResponse response) {
        onError(response.message ?? "Payment Failed");
      },
    );
  }

  void openCheckout({
    required int amount,
    required String name,
    required String description,
    required String email,
    required String phone,
  }) {
    final options = {
      'key': liveKey,
      'amount': amount * 100, // paisa
      'name': name,
      'description': description,
      'prefill': {
        'email': email,
        'contact': phone,
      },
      'theme': {
        'color': '#FF0000',
      }
    };

    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
