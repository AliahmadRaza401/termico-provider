import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../app_configuration.dart';
import '../common.dart';

extension NumExtension on num {
  String toPriceFormat() {
    if (isAppleReviewFreeMode) {
      return languages.lblFree;
    }

    return "${isCurrencyPositionLeft ? appConfigurationStore.currencySymbol : ''}${this.toStringAsFixed(appConfigurationStore.priceDecimalPoint).formatNumberWithComma()}${isCurrencyPositionRight ? appConfigurationStore.currencySymbol : ''}";
  }
}
