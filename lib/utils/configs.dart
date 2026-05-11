import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

const APP_NAME = 'Tehnico Provider';
const DEFAULT_LANGUAGE = 'ro';

const primaryColor = Color(0xFF0e7cdc);

/// Live Url
const DOMAIN_URL = "https://tehnico.md";

const BASE_URL = "$DOMAIN_URL/api/";

/// You can specify in Admin Panel, These will be used if you don't specify in Admin Panel
const IOS_LINK_FOR_PARTNER =
    "https://apps.apple.com/in/app/tehnico-provider-app/id1596025324";
const TERMS_CONDITION_URL = '$DOMAIN_URL/terms-of-use/';
const PRIVACY_POLICY_URL = '$DOMAIN_URL/privacy-policy/';
const HELP_AND_SUPPORT_URL = '$DOMAIN_URL/privacy-policy/';
const REFUND_POLICY_URL = '$DOMAIN_URL/licensing-terms-more/#refund-policy';
const INQUIRY_SUPPORT_EMAIL = 'info@tehnico.md';

/// You can add help line number here for contact. It's demo number
const HELP_LINE_NUMBER = '+15265897485';

//Airtel Money Payments
///It Supports ["UGX", "NGN", "TZS", "KES", "RWF", "ZMW", "CFA", "XOF", "XAF", "CDF", "USD", "XAF", "SCR", "MGA", "MWK"]
const AIRTEL_CURRENCY_CODE = "MWK";
const AIRTEL_COUNTRY_CODE = "MW";
const AIRTEL_TEST_BASE_URL = 'https://openapiuat.airtel.africa/'; //Test Url
const AIRTEL_LIVE_BASE_URL = 'https://openapi.airtel.africa/'; // Live Url

/// PAYSTACK PAYMENT DETAIL
const PAYSTACK_CURRENCY_CODE = 'NGN';

/// SADAD PAYMENT DETAIL
const SADAD_API_URL = 'https://api-s.sadad.qa';
const SADAD_PAY_URL = "https://d.sadad.qa";

/// RAZORPAY PAYMENT DETAIL
const RAZORPAY_CURRENCY_CODE = 'INR';

/// PAYPAL PAYMENT DETAIL
const PAYPAL_CURRENCY_CODE = 'USD';

/// STRIPE PAYMENT DETAIL
const STRIPE_MERCHANT_COUNTRY_CODE = 'US';
const STRIPE_CURRENCY_CODE = 'USD';

Country defaultCountry() {
  return Country(
    phoneCode: '1',
    countryCode: 'US',
    e164Sc: 1,
    geographic: true,
    level: 1,
    name: 'United States',
    example: '2015550123',
    displayName: 'United States (US) [+1]',
    displayNameNoCountryCode: 'United States (US)',
    e164Key: '1-US-0',
    fullExampleWithPlusSign: '+12015550123',
  );
}

//Chat Module File Upload Configs
const chatFilesAllowedExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp', // Images
  'pdf', 'txt', // Documents
  'mkv', 'mp4', // Video
  'mp3', // Audio
];
const max_acceptable_file_size = 5; //Size in Mb
