import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../utils/app_configuration.dart';

class PayPalService {
  static Future paypalCheckOut({
    required BuildContext context,
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) async {
    appStore.setLoading(false);
    throw 'PayPal payments are disabled in this build.';
  }
}
