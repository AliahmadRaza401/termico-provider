import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../main.dart';
import '../../../../utils/app_configuration.dart';
import 'airtel_payment_response.dart';
import 'aritel_auth_model.dart';

class AirtelMoneyDialog extends StatelessWidget {
  final String reference;
  final int bookingId;
  final PaymentSetting paymentSetting;
  final num amount;
  final Function(Map<String, dynamic>) onComplete;

  const AirtelMoneyDialog({
    super.key,
    required this.onComplete,
    required this.reference,
    required this.bookingId,
    required this.amount,
    required this.paymentSetting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Airtel Money payments are disabled in this build.',
            style: boldTextStyle(),
            textAlign: TextAlign.center,
          ),
          12.height,
          AppButton(
            text: languages.lblCancel,
            onTap: () => finish(context),
          ),
        ],
      ),
    );
  }
}

Future<AirtelAuthModel> authorizeAirtelClient(
    PaymentSetting currentPaymentMethod) async {
  throw UnsupportedError('Airtel Money payments are disabled in this build.');
}

Future<AirtelPaymentResponse> paymentAirtelClient({
  required String accessToken,
  required String txnId,
  required num totalAmount,
  required String phoneNumber,
  required PaymentSetting currentPaymentMethod,
}) async {
  throw UnsupportedError('Airtel Money payments are disabled in this build.');
}

Future<bool> checkAirtelPaymentStatus({
  required String txnId,
  required Function(bool) loderOnOFF,
  required PaymentSetting currentPaymentMethod,
}) async {
  throw UnsupportedError('Airtel Money payments are disabled in this build.');
}

(String, String) getAirtelMoneyReasonTextFromCode(String code) {
  return ('Unavailable', 'Airtel Money payments are disabled in this build.');
}

class AirtelMoneyResponseCodes {
  static const String SUCCESS = 'SUCCESS';
  static const String IN_PROCESS = 'IN_PROCESS';
}
