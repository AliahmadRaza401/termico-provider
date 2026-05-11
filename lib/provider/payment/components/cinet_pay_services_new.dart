import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../utils/app_configuration.dart';

class CinetPayServicesNew {
  late PaymentSetting paymentSetting;
  num totalAmount;
  late Function(Map<String, dynamic>) onComplete;

  CinetPayServicesNew({
    required this.paymentSetting,
    required this.totalAmount,
    required Function(Map) onComplete,
  }) {
    this.onComplete = onComplete;
  }

  Future<void> payWithCinetPay({required BuildContext context}) async {
    appStore.setLoading(false);
    throw 'CinetPay payments are disabled in this build.';
  }
}
