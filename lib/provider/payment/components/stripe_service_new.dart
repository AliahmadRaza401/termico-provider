import '../../../main.dart';
import '../../../utils/app_configuration.dart';

class StripeServiceNew {
  late PaymentSetting paymentSetting;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;

  StripeServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  Future<dynamic> stripePay() async {
    appStore.setLoading(false);
    throw 'Stripe payments are disabled in this build.';
  }
}
