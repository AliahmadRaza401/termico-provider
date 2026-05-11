import 'package:flutter/material.dart';

import '../../../../main.dart';
import '../../../../utils/app_configuration.dart';

class PhonePeServices {
  late PaymentSetting paymentSetting;
  int bookingId = 0;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;
  bool isTest = false;
  String environmentValue = '';
  String appId = '';
  String merchantId = '';
  String saltKey = '';
  String saltIndex = '1';

  PhonePeServices({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    int bookingId = 0,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
    this.bookingId = bookingId;
  }

  final phonePeTestEnvironment = 'UAT';
  final phonePeLiveEnvironment = 'PhonePeEnvironment.RELEASE';

  Future<void> phonePeCheckout(BuildContext context) async {
    appStore.setLoading(false);
    throw 'PhonePe payments are disabled in this build.';
  }
}

void getPackageSignatureForAndroid() {
  return;
}
