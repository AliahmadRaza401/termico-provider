import '../../../utils/app_configuration.dart';

class MidtransService {
  num totalAmount = 0;
  int serviceId = 0;
  num servicePrice = 0;
  String serviceName = '';
  late Function(Map<String, dynamic>) onComplete;
  late Function(bool) loaderOnOFF;
  late PaymentSetting currentPaymentMethod;

  initialize({
    required PaymentSetting currentPaymentMethod,
    required num totalAmount,
    int? serviceId,
    num? servicePrice,
    String? serviceName,
    required Function(Map<String, dynamic>) onComplete,
    required Function(bool) loaderOnOFF,
  }) {
    this.currentPaymentMethod = currentPaymentMethod;
    this.totalAmount = totalAmount;
    this.serviceId = serviceId ?? 0;
    this.servicePrice = servicePrice ?? 0;
    this.serviceName = serviceName ?? '';
    this.onComplete = onComplete;
    this.loaderOnOFF = loaderOnOFF;
  }

  Future midtransPaymentCheckout() async {
    loaderOnOFF(false);
    throw 'Midtrans payments are disabled in this build.';
  }
}
