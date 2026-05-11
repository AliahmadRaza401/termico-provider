import '../../../main.dart';
import '../../../utils/app_configuration.dart';

class FlutterWaveServiceNew {
  void checkout({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map) onComplete,
  }) async {
    appStore.setLoading(false);
    throw 'Flutterwave payments are disabled in this build.';
  }
}
