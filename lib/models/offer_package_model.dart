class OfferPackageModel {
  int? id;
  String? name;
  num? price;
  int? offersPerMonth;
  String? description;
  int? status;
  int? freeMonth;

  OfferPackageModel({
    this.id,
    this.name,
    this.price,
    this.offersPerMonth,
    this.description,
    this.status,
    this.freeMonth,
  });

  factory OfferPackageModel.fromJson(Map<String, dynamic> json) {
    return OfferPackageModel(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      offersPerMonth: json['offers_per_month'],
      description: json['description'],
      status: json['status'],
      freeMonth: json['free_month'] != null
          ? int.tryParse(json['free_month'].toString())
          : null,
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
    data['free_month'] = this.freeMonth;
    return data;
  }
}

class OfferPackageListResponse {
  List<OfferPackageModel>? data;

  OfferPackageListResponse({this.data});

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
  int? freeMonth;

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
    this.freeMonth,
  });

  factory OfferPackageStatusModel.fromJson(Map<String, dynamic> json) {
    final bool? hasActivePackage =
        json['has_active_package'] is bool ? json['has_active_package'] : null;
    final bool? hasPackage =
        json['has_package'] is bool ? json['has_package'] : null;
    final int? packageId = json['package_id'] is int
        ? json['package_id']
        : int.tryParse('${json['package_id'] ?? ''}');

    return OfferPackageStatusModel(
      hasActivePackage: hasActivePackage,
      // Some responses omit has_package but still provide an active package payload.
      hasPackage: hasPackage ?? hasActivePackage ?? (packageId != null),
      packageId: packageId,
      packageName: json['package_name'],
      packagePrice: json['package_price'],
      offersPerMonth: json['offers_per_month'],
      offersUsed: json['offers_used'],
      offersRemaining: json['offers_remaining'],
      status: json['status'],
      startAt: json['start_at'],
      endAt: json['end_at'],
      paymentId: json['payment_id']?.toString(),
      paymentMethodName: json['payment_method_name']?.toString(),
      canSendOffer: json['can_send_offer'],
      freeMonth: json['free_month'] != null
          ? int.tryParse(json['free_month'].toString())
          : null,
    );
  }

  // Helper method to parse date string (handles both ISO 8601 and standard formats)
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      // Try parsing as ISO 8601 format first (e.g., "2026-01-18T17:11:56.000000Z")
      if (dateString.contains('T') || dateString.contains('Z')) {
        return DateTime.parse(dateString);
      }

      // Try parsing standard format (e.g., "2026-04-18 20:12:14")
      // Replace space with T to make it parseable
      String normalizedDate = dateString.replaceFirst(' ', 'T');
      // If no timezone info, add Z for UTC or parse as local
      if (!normalizedDate.contains('Z') &&
          !normalizedDate.contains('+') &&
          !normalizedDate.contains('-', 10)) {
        return DateTime.parse(normalizedDate);
      }

      return DateTime.parse(normalizedDate);
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  // Helper method to check if we're in a free month period (unlimited offers)
  bool get isInFreeMonthPeriod {
    // If freeMonth is null or 0, not in free period
    if (freeMonth == null || freeMonth! <= 0) {
      return false;
    }

    // If startAt or endAt is missing, cannot determine free period
    if (startAt == null ||
        startAt!.isEmpty ||
        endAt == null ||
        endAt!.isEmpty) {
      return false;
    }

    DateTime? startDate = _parseDate(startAt);
    DateTime? endDate = _parseDate(endAt);

    if (startDate == null || endDate == null) {
      return false;
    }

    DateTime now = DateTime.now();

    // Check if current date is within the free period (from start_at to end_at)
    return now.isAfter(startDate.subtract(Duration(seconds: 1))) &&
        now.isBefore(endDate.add(Duration(seconds: 1)));
  }

  // Helper method to check if user can send offers
  bool get canSendOffers {
    final bool hasAnyPackage =
        hasPackage ?? hasActivePackage ?? (packageId != null);
    final bool isActivePackage =
        hasActivePackage ?? (status?.toLowerCase() == 'active');

    // Check if user has no package at all
    if (!hasAnyPackage || !isActivePackage) {
      return false;
    }

    // If package is not active, cannot send offers
    if (status?.toLowerCase() != 'active') {
      return false;
    }

    // If in free month period (freeMonth > 0 and within date range), allow unlimited offers
    if (isInFreeMonthPeriod) {
      return true;
    }

    // Otherwise, check if package has remaining offers
    if (offersRemaining != null && offersRemaining! > 0) {
      return true;
    }

    return false;
  }

  // Helper method to get the reason why user cannot send offers
  String get cannotSendOfferReason {
    final bool hasAnyPackage =
        hasPackage ?? hasActivePackage ?? (packageId != null);
    final bool isActivePackage =
        hasActivePackage ?? (status?.toLowerCase() == 'active');

    if (!hasAnyPackage) {
      return 'no_subscription';
    }
    if (!isActivePackage || status?.toLowerCase() != 'active') {
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
    data['free_month'] = this.freeMonth;
    return data;
  }
}

class OfferPackageStatusResponse {
  OfferPackageStatusModel? data;
  String? message;

  OfferPackageStatusResponse({this.data, this.message});

  factory OfferPackageStatusResponse.fromJson(Map<String, dynamic> json) {
    return OfferPackageStatusResponse(
      data: json['data'] != null
          ? OfferPackageStatusModel.fromJson(json['data'])
          : null,
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
