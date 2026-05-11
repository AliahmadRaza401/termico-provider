import 'package:flutter/cupertino.dart';

import '../../../main.dart';
import '../../../utils/app_configuration.dart';

class SadadServicesNew {
  late PaymentSetting paymentSetting;
  String remarks;
  num totalAmount;
  late Function(Map<String, dynamic>) onComplete;

  SadadServicesNew({
    required this.paymentSetting,
    required this.totalAmount,
    this.remarks = '',
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.onComplete = onComplete;
  }

  Future<void> payWithSadad(BuildContext context) async {
    appStore.setLoading(false);
    throw 'Sadad payments are disabled in this build.';
  }
}
