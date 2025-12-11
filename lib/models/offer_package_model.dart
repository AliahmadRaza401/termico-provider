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

class OfferPackageListResponse {
  List<OfferPackageModel>? data;

  OfferPackageListResponse({this.data});

  factory OfferPackageListResponse.fromJson(Map<String, dynamic> json) {
    return OfferPackageListResponse(
      data: json['data'] != null
          ? (json['data'] as List).map((i) => OfferPackageModel.fromJson(i)).toList()
          : null,
    );
  }
}

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

  OfferPackageStatusModel({
    this.hasActivePackage,
    this.hasPackage,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.offersPerMonth,
    this.offersUsed,
    this.offersRemaining,
    this.status,
    this.startAt,
    this.endAt,
    this.paymentId,
    this.paymentMethodName,
    this.canSendOffer,
  });

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

  // Helper method to check if user can send offers
  bool get canSendOffers {
    // Check if user has no package at all
    if (hasPackage == false || hasActivePackage == false) {
      return false;
    }
    // Check if package is active and has remaining offers
    if (status?.toLowerCase() == 'active' && offersRemaining != null && offersRemaining! > 0) {
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['has_active_package'] = this.hasActivePackage;
    data['has_package'] = this.hasPackage;
    data['package_id'] = this.packageId;
    data['package_name'] = this.packageName;
    data['package_price'] = this.packagePrice;
    data['offers_per_month'] = this.offersPerMonth;
    data['offers_used'] = this.offersUsed;
    data['offers_remaining'] = this.offersRemaining;
    data['status'] = this.status;
    data['start_at'] = this.startAt;
    data['end_at'] = this.endAt;
    data['payment_id'] = this.paymentId;
    data['payment_method_name'] = this.paymentMethodName;
    data['can_send_offer'] = this.canSendOffer;
    return data;
  }
}

class OfferPackageStatusResponse {
  OfferPackageStatusModel? data;
  String? message;

  OfferPackageStatusResponse({this.data, this.message});

  factory OfferPackageStatusResponse.fromJson(Map<String, dynamic> json) {
    return OfferPackageStatusResponse(
      data: json['data'] != null ? OfferPackageStatusModel.fromJson(json['data']) : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = this.message;
    return data;
  }
}

