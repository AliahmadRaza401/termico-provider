import 'package:flutter/cupertino.dart';

import '../../../utils/app_configuration.dart';

class PayStackService {
  late BuildContext ctx;
  num totalAmount = 0;
  int bookingId = 0;
  late Function(Map<String, dynamic>) onComplete;
  late Function(bool) loderOnOFF;
  late PaymentSetting currentPaymentMethod;

  init({
    required BuildContext context,
    required PaymentSetting currentPaymentMethod,
    required num totalAmount,
    required int bookingId,
    required Function(Map<String, dynamic>) onComplete,
    required Function(bool) loderOnOFF,
  }) {
    ctx = context;
    this.currentPaymentMethod = currentPaymentMethod;
    this.totalAmount = totalAmount;
    this.bookingId = bookingId;
    this.onComplete = onComplete;
    this.loderOnOFF = loderOnOFF;
  }

  Future checkout() async {
    loderOnOFF(false);
    throw 'Paystack payments are disabled in this build.';
  }
}
