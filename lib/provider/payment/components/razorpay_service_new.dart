import '../../../main.dart';
import '../../../utils/app_configuration.dart';

class RazorPayServiceNew {
  late PaymentSetting paymentSetting;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;

  RazorPayServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  Future<void> razorPayCheckout() async {
    appStore.setLoading(false);
    throw 'Razorpay payments are disabled in this build.';
  }
}
