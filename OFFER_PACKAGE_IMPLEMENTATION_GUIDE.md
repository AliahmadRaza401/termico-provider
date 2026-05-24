# Offer Package Implementation Guide

Complete documentation for implementing the Offer Package feature in a Flutter application. This guide covers all APIs, models, UI components, state management, and integration points.

---

## Table of Contents
1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Data Models](#data-models)
4. [State Management](#state-management)
5. [UI Implementation](#ui-implementation)
6. [Integration Points](#integration-points)
7. [Constants & Localization](#constants--localization)
8. [Step-by-Step Implementation](#step-by-step-implementation)

---

## Overview

The Offer Package system allows providers to purchase packages that grant them a certain number of job offers/bids per month. The system includes:
- Package listing and purchase
- Package status tracking
- Offer usage monitoring
- Validation before sending bids/offers

**Key Features:**
- Display available packages
- Show current purchased package status
- Prevent duplicate purchases
- Validate package status before allowing bids
- Track offers used vs remaining
- Handle package expiration

---

## API Endpoints

### 1. Get Offer Package List
**Endpoint:** `offer-package-list`  
**Method:** `GET`  
**Authentication:** Required (Bearer token in headers)

**Response Structure:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Free",
      "price": 0,
      "offers_per_month": 5,
      "description": "Basic package with limited offers",
      "status": 1
    },
    {
      "id": 2,
      "name": "Premium",
      "price": 99.99,
      "offers_per_month": 50,
      "description": "Premium package with more offers",
      "status": 1
    }
  ]
}
```

**Implementation:**
```dart
Future<List<OfferPackageModel>> getOfferPackageList() async {
  try {
    OfferPackageListResponse res = OfferPackageListResponse.fromJson(
      await handleResponse(
        await buildHttpResponse('offer-package-list', method: HttpMethodType.GET)
      ),
    );
    appStore.setLoading(false);
    return res.data.validate();
  } catch (e) {
    appStore.setLoading(false);
    throw e;
  }
}
```

**Notes:**
- Filter packages by `status == 1` (active packages only)
- Handle errors gracefully
- Set loading state appropriately

---

### 2. Buy Offer Package
**Endpoint:** `buy-offer-package`  
**Method:** `POST` (Multipart)  
**Authentication:** Required

**Request Parameters:**
- `offer_package_id` (int, required): The ID of the package to purchase
- `payment_id` (string, optional): Payment transaction ID
- `payment_method_name` (string, optional): Payment method name

**Request Example:**
```
offer_package_id: 4
payment_id: ""
payment_method_name: ""
```

**Response Structure:**
```json
{
  "status": 200,
  "message": "Package purchased successfully"
}
```

**Implementation:**
```dart
Future<BaseResponseModel> buyOfferPackage({
  required int offerPackageId,
  String? paymentId,
  String? paymentMethodName,
}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('buy-offer-package');
  
  multiPartRequest.fields['offer_package_id'] = offerPackageId.toString();
  multiPartRequest.fields['payment_id'] = paymentId ?? '';
  multiPartRequest.fields['payment_method_name'] = paymentMethodName ?? '';
  
  multiPartRequest.headers.addAll(buildHeaderTokens());
  appStore.setLoading(true);
  
  BaseResponseModel? response;
  
  await sendMultiPartRequest(
    multiPartRequest,
    onSuccess: (temp) async {
      appStore.setLoading(false);
      response = BaseResponseModel.fromJson(jsonDecode(temp));
    },
    onError: (error) {
      appStore.setLoading(false);
      throw error;
    },
  );
  
  return response!;
}
```

**Notes:**
- Use multipart request for form data
- Handle demo user/tester restrictions
- Update local state after successful purchase
- Refresh package status after purchase

---

### 3. Get Offer Package Status
**Endpoint:** `get-offer-package-status`  
**Method:** `GET`  
**Authentication:** Required

**Response Structure:**
```json
{
  "data": {
    "has_active_package": true,
    "has_package": true,
    "package_id": 4,
    "package_name": "Free",
    "package_price": 0,
    "offers_per_month": 5,
    "offers_used": 0,
    "offers_remaining": 5,
    "status": "active",
    "start_at": "2025-11-27T14:11:50.000000Z",
    "end_at": "2025-12-27T14:11:50.000000Z",
    "payment_id": null,
    "payment_method_name": null,
    "can_send_offer": true
  },
  "message": "messages.package_status_retrieved"
}
```

**Implementation:**
```dart
Future<OfferPackageStatusResponse> getOfferPackageStatus() async {
  try {
    var response = await buildHttpResponse(
      'get-offer-package-status', 
      method: HttpMethodType.GET
    );
    var responseData = await handleResponse(response);
    
    OfferPackageStatusResponse res = OfferPackageStatusResponse.fromJson(responseData);
    appStore.setLoading(false);
    
    return res;
  } catch (e) {
    appStore.setLoading(false);
    throw e;
  }
}
```

**Notes:**
- Call this API before allowing bids/offers
- Check `can_send_offer` or use helper methods
- Handle null responses gracefully
- Cache status for UI updates

---

## Data Models

### OfferPackageModel
```dart
class OfferPackageModel {
  int? id;
  String? name;
  num? price;
  int? offersPerMonth;
  String? description;
  int? status;

  OfferPackageModel({
    this.id,
    this.name,
    this.price,
    this.offersPerMonth,
    this.description,
    this.status,
  });

  factory OfferPackageModel.fromJson(Map<String, dynamic> json) {
    return OfferPackageModel(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      offersPerMonth: json['offers_per_month'],
      description: json['description'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['price'] = this.price;
    data['offers_per_month'] = this.offersPerMonth;
    data['description'] = this.description;
    data['status'] = this.status;
    return data;
  }
}
```

### OfferPackageStatusModel
```dart
class OfferPackageStatusModel {
  bool? hasActivePackage;
  bool? hasPackage;
  int? packageId;
  String? packageName;
  num? packagePrice;
  int? offersPerMonth;
  int? offersUsed;
  int? offersRemaining;
  String? status;
  String? startAt;
  String? endAt;
  String? paymentId;
  String? paymentMethodName;
  bool? canSendOffer;

  // Helper method to check if user can send offers
  bool get canSendOffers {
    if (hasPackage == false || hasActivePackage == false) {
      return false;
    }
    if (status?.toLowerCase() == 'active' && 
        offersRemaining != null && 
        offersRemaining! > 0) {
      return true;
    }
    return false;
  }

  // Helper method to get the reason why user cannot send offers
  String get cannotSendOfferReason {
    if (hasPackage == false || hasActivePackage == false) {
      return 'no_subscription';
    }
    if (status?.toLowerCase() != 'active') {
      return 'package_ended';
    }
    if (offersRemaining != null && offersRemaining! <= 0) {
      return 'no_offers_remaining';
    }
    return 'unknown';
  }

  factory OfferPackageStatusModel.fromJson(Map<String, dynamic> json) {
    return OfferPackageStatusModel(
      hasActivePackage: json['has_active_package'],
      hasPackage: json['has_package'],
      packageId: json['package_id'],
      packageName: json['package_name'],
      packagePrice: json['package_price'],
      offersPerMonth: json['offers_per_month'],
      offersUsed: json['offers_used'],
      offersRemaining: json['offers_remaining'],
      status: json['status'],
      startAt: json['start_at'],
      endAt: json['end_at'],
      paymentId: json['payment_id'],
      paymentMethodName: json['payment_method_name'],
      canSendOffer: json['can_send_offer'],
    );
  }
}
```

### Response Models
```dart
class OfferPackageListResponse {
  List<OfferPackageModel>? data;
  
  factory OfferPackageListResponse.fromJson(Map<String, dynamic> json) {
    return OfferPackageListResponse(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((i) => OfferPackageModel.fromJson(i))
              .toList()
          : null,
    );
  }
}

class OfferPackageStatusResponse {
  OfferPackageStatusModel? data;
  String? message;
  
  factory OfferPackageStatusResponse.fromJson(Map<String, dynamic> json) {
    return OfferPackageStatusResponse(
      data: json['data'] != null 
          ? OfferPackageStatusModel.fromJson(json['data']) 
          : null,
      message: json['message'],
    );
  }
}
```

---

## State Management

### AppStore Variables (MobX Observable)
```dart
@observable
bool hasOfferPackage = getBoolAsync(HAS_OFFER_PACKAGE);

@observable
String offerPackageName = getStringAsync(OFFER_PACKAGE_NAME);

@observable
int offerPackageOffersPerMonth = getIntAsync(OFFER_PACKAGE_OFFERS_PER_MONTH);

@observable
int offerPackageId = getIntAsync(OFFER_PACKAGE_ID);
```

### AppStore Actions
```dart
@action
Future<void> setHasOfferPackage(bool val) async {
  hasOfferPackage = val;
  await setValue(HAS_OFFER_PACKAGE, val);
}

@action
Future<void> setOfferPackageName(String val) async {
  offerPackageName = val;
  await setValue(OFFER_PACKAGE_NAME, val);
}

@action
Future<void> setOfferPackageOffersPerMonth(int val) async {
  offerPackageOffersPerMonth = val;
  await setValue(OFFER_PACKAGE_OFFERS_PER_MONTH, val);
}

@action
Future<void> setOfferPackageId(int val) async {
  offerPackageId = val;
  await setValue(OFFER_PACKAGE_ID, val);
}
```

**Usage:**
- Store package info after purchase
- Persist to local storage using `setValue()`
- Access via `appStore.hasOfferPackage`, `appStore.offerPackageName`, etc.

---

## UI Implementation

### 1. Offer Package List Screen

**Key Features:**
- Display purchased package card at top (if exists)
- Show available packages below
- Disable purchased packages visually
- Refresh functionality
- Loading states

**Screen Structure:**
```dart
class OfferPackageListScreen extends StatefulWidget {
  @override
  _OfferPackageListScreenState createState() => _OfferPackageListScreenState();
}

class _OfferPackageListScreenState extends State<OfferPackageListScreen> {
  Future<List<OfferPackageModel>>? future;
  List<OfferPackageModel> offerPackageList = [];
  OfferPackageStatusModel? purchasedPackageStatus;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    // Load package list and status in parallel
    future = Future.wait([
      getOfferPackageList(),
      getOfferPackageStatus().catchError((e) {
        log('Error loading package status: $e');
        return OfferPackageStatusResponse();
      }),
    ]).then((results) {
      List<OfferPackageModel> packages = results[0] as List<OfferPackageModel>;
      offerPackageList = packages.where((pkg) => pkg.status == 1).toList();
      
      OfferPackageStatusResponse statusResponse = results[1] as OfferPackageStatusResponse;
      purchasedPackageStatus = statusResponse.data;
      
      setState(() {});
      return offerPackageList;
    });
  }
}
```

**Purchased Package Card:**
- Show package name from API (`packageName`)
- Display status badge (active/expired)
- Show offers used vs remaining
- Display start/end dates
- Use green/orange color scheme based on status

**Available Package Card:**
- Show package name and price
- Display offers per month
- Show description
- Buy button (disabled if already purchased)
- Visual indicators for purchased packages (opacity, grey border, "PURCHASED" badge)

**Purchase Flow:**
1. Show confirmation dialog
2. Call `buyOfferPackage()` API
3. Update AppStore with package info
4. Refresh package status
5. Show success toast
6. Navigate back

---

### 2. Job Post Detail Screen Integration

**Validation Before Bid:**
```dart
Future<void> checkOfferPackageStatus() async {
  try {
    OfferPackageStatusResponse response = await getOfferPackageStatus();
    offerPackageStatus = response.data;
    setState(() {});
  } catch (e) {
    log('Error checking offer package status: $e');
  }
}

// In bid button onTap:
onTap: () async {
  appStore.setLoading(true);
  setState(() {});
  
  try {
    await checkOfferPackageStatus();
    appStore.setLoading(false);
    setState(() {});
    
    if (offerPackageStatus == null) {
      toast('Unable to check offer package status. Please try again.');
      return;
    }
  } catch (e) {
    appStore.setLoading(false);
    setState(() {});
    toast('Error checking offer package status. Please try again.');
    return;
  }

  bool canSendOffer = offerPackageStatus!.canSendOffers;
  
  if (!canSendOffer) {
    String reason = offerPackageStatus!.cannotSendOfferReason;
    String toastMessage = '';
    String dialogTitle = '';
    
    if (reason == 'no_subscription') {
      toastMessage = 'You do not have an offer package subscription...';
      dialogTitle = 'No Offer Package Subscription';
    } else if (reason == 'package_ended') {
      toastMessage = 'Your offer package has ended...';
      dialogTitle = 'Offer Package Ended';
    } else if (reason == 'no_offers_remaining') {
      toastMessage = 'You have no remaining offers...';
      dialogTitle = 'No Offers Remaining';
    }
    
    toast(toastMessage);
    
    showConfirmDialogCustom(
      context,
      title: dialogTitle,
      positiveText: languages.lblBuy,
      negativeText: languages.lblCancel,
      onAccept: (dialogContext) async {
        finish(dialogContext);
        await Future.delayed(Duration(milliseconds: 100));
        bool? result = await OfferPackageListScreen().launch(context);
        if (result == true) {
          await checkOfferPackageStatus();
          setState(() {});
        }
      },
    );
    return;
  }

  // Proceed with bid if user can send offers
  // ... bid dialog logic
}
```

**Key Points:**
- Check status before allowing bid
- Show appropriate error messages
- Navigate to package list if needed
- Refresh status after purchase

---

## Constants & Localization

### Constants (constant.dart)
```dart
const HAS_OFFER_PACKAGE = 'HAS_OFFER_PACKAGE';
const OFFER_PACKAGE_NAME = 'OFFER_PACKAGE_NAME';
const OFFER_PACKAGE_OFFERS_PER_MONTH = 'OFFER_PACKAGE_OFFERS_PER_MONTH';
const OFFER_PACKAGE_ID = 'OFFER_PACKAGE_ID';
```

### Localization Keys (base_language.dart)
```dart
abstract class Languages {
  String get lblJobOfferPackages;
  String get lblOffersPerMonth;
  String get lblBuy;
  String get lblSuccess;
  // ... other keys
}
```

### Language Implementations
**English:**
```dart
@override
String get lblJobOfferPackages => 'Job Offer Packages';

@override
String get lblOffersPerMonth => 'offers per month';

@override
String get lblBuy => 'Buy';

@override
String get lblSuccess => 'Success';
```

**Romanian:**
```dart
@override
String get lblJobOfferPackages => 'Pachete Oferte de Job';

@override
String get lblOffersPerMonth => 'oferte pe lună';

@override
String get lblBuy => 'Cumpără';

@override
String get lblSuccess => 'Succes';
```

**Russian:**
```dart
@override
String get lblJobOfferPackages => 'Пакеты Предложений Работы';

@override
String get lblOffersPerMonth => 'предложений в месяц';

@override
String get lblBuy => 'Купить';

@override
String get lblSuccess => 'Успех';
```

---

## Integration Points

### 1. Profile Screen
Add navigation to offer package list:
```dart
SettingItemWidget(
  name: languages.lblJobOfferPackages,
  onTap: () {
    OfferPackageListScreen().launch(context);
  },
)
```

### 2. Job Post Detail Screen
- Check package status before bid
- Show validation messages
- Navigate to package purchase if needed

### 3. After Purchase
- Update AppStore state
- Refresh package status
- Show success message
- Navigate back to previous screen

---

## Step-by-Step Implementation

### Step 1: Create Data Models
1. Create `offer_package_model.dart` file
2. Implement `OfferPackageModel`, `OfferPackageStatusModel`, and response models
3. Add helper methods (`canSendOffers`, `cannotSendOfferReason`)

### Step 2: Add API Methods
1. Add `getOfferPackageList()` in `rest_apis.dart`
2. Add `buyOfferPackage()` in `rest_apis.dart`
3. Add `getOfferPackageStatus()` in `rest_apis.dart`
4. Handle errors and loading states

### Step 3: Add State Management
1. Add constants in `constant.dart`
2. Add observable variables in `AppStore`
3. Add action methods in `AppStore`
4. Initialize from local storage

### Step 4: Add Localization
1. Add keys to `base_language.dart`
2. Implement in all language files (en, ro, ru, etc.)

### Step 5: Create UI Screens
1. Create `OfferPackageListScreen`
   - Implement package list display
   - Add purchased package card
   - Add purchase flow
   - Add refresh functionality
2. Integrate in `JobPostDetailScreen`
   - Add status check before bid
   - Add validation logic
   - Add navigation to package list

### Step 6: Add Navigation
1. Add menu item in profile screen
2. Handle navigation after purchase
3. Handle back navigation with result

### Step 7: Testing
1. Test package listing
2. Test package purchase
3. Test status checking
4. Test validation before bid
5. Test error scenarios
6. Test refresh functionality

---

## Important Notes

### 1. Package Status Logic
- Use `hasActivePackage` OR `hasPackage` to determine if purchased package should be shown
- Match purchased package by `packageId` from status response
- Use `packageName` directly from API response (not from package list)

### 2. Purchase Prevention
- Check `packageId` match before allowing purchase
- Show visual indicators (opacity, disabled state) for purchased packages
- Add safety check in `buyPackage()` method

### 3. Status Validation
- Always check status before allowing bids/offers
- Use helper methods (`canSendOffers`, `cannotSendOfferReason`)
- Show appropriate error messages based on reason

### 4. Error Handling
- Handle null responses gracefully
- Catch errors in API calls
- Show user-friendly error messages
- Continue app flow even if status check fails (in some cases)

### 5. Loading States
- Show loading indicators during API calls
- Set `appStore.setLoading(true/false)` appropriately
- Use `Observer` widget for reactive updates

### 6. Date Formatting
- Use `formatDate()` utility for displaying dates
- Format: `DATE_FORMAT_1` (typically "MMM dd, yyyy")

### 7. Price Formatting
- Use `toPriceFormat()` extension on `num` type
- Handles currency symbol positioning
- Formats decimal places

---

## API Response Examples

### Get Package List Response
```json
{
  "data": [
    {
      "id": 1,
      "name": "Free",
      "price": 0,
      "offers_per_month": 5,
      "description": "Basic package",
      "status": 1
    }
  ]
}
```

### Get Package Status Response
```json
{
  "data": {
    "has_active_package": true,
    "has_package": true,
    "package_id": 4,
    "package_name": "Free",
    "package_price": 0,
    "offers_per_month": 5,
    "offers_used": 0,
    "offers_remaining": 5,
    "status": "active",
    "start_at": "2025-11-27T14:11:50.000000Z",
    "end_at": "2025-12-27T14:11:50.000000Z",
    "payment_id": null,
    "payment_method_name": null,
    "can_send_offer": true
  },
  "message": "messages.package_status_retrieved"
}
```

### Buy Package Response
```json
{
  "status": 200,
  "message": "Package purchased successfully"
}
```

---

## File Structure

```
lib/
├── models/
│   └── offer_package_model.dart
├── networks/
│   └── rest_apis.dart (add API methods)
├── provider/
│   └── offer_package/
│       └── offer_package_list_screen.dart
├── provider/
│   └── jobRequest/
│       └── job_post_detail_screen.dart (integrate validation)
├── store/
│   └── AppStore.dart (add state management)
├── utils/
│   └── constant.dart (add constants)
└── locale/
    ├── base_language.dart (add keys)
    ├── language_en.dart (implement)
    ├── language_ro.dart (implement)
    ├── language_ru.dart (implement)
    └── ... (other languages)
```

---

## Summary Checklist

- [ ] Create data models (`OfferPackageModel`, `OfferPackageStatusModel`)
- [ ] Implement API methods (get list, buy, get status)
- [ ] Add state management (AppStore observables and actions)
- [ ] Add constants for local storage keys
- [ ] Add localization keys and implementations
- [ ] Create offer package list screen
- [ ] Integrate validation in job post detail screen
- [ ] Add navigation from profile screen
- [ ] Test all flows and error scenarios
- [ ] Handle edge cases (null responses, expired packages, etc.)

---

**End of Documentation**
