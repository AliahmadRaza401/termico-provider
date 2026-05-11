import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../models/service_model.dart';

class PostJobData {
  num? id;
  String? title;
  String? description;
  String? reason;
  num? price;
  num? jobPrice;
  num? providerId;
  num? customerId;
  String? status;
  String? customerName;
  String? createdAt;
  bool? canBid;
  List<ServiceData>? service;
  String? customerProfile;
  // 👇 New fields
  double? latitude;
  double? longitude;
  String? address;
  int? expiryDays;
  String? requestType;

  PostJobData({
    this.id,
    this.title,
    this.description,
    this.reason,
    this.price,
    this.providerId,
    this.customerId,
    this.status,
    this.canBid,
    this.service,
    this.jobPrice,
    this.createdAt,
    this.customerName,
    this.customerProfile,
    this.latitude,
    this.longitude,
    this.address,
    this.expiryDays,
    this.requestType,
  });

  PostJobData.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    reason = json['reason'];
    price = json['price'];
    jobPrice = json['job_price'];
    providerId = json['provider_id'];
    customerId = json['customer_id'];
    customerName = json['customer_name'];
    status = json['status'];
    customerProfile = json['customer_profile'];
    canBid = json['can_bid'];
    createdAt = json['created_at'];
    // 👇 Map new fields
    latitude = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString())
        : null;
    longitude = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : null;
    address = json['address'];
    expiryDays = json['expiry_days'] != null ? int.tryParse(json['expiry_days'].toString()) : null;
    requestType = json['request_type'];

    if (json['service'] != null) {
      service = [];
      json['service'].forEach((v) {
        service?.add(ServiceData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['reason'] = reason;
    map['price'] = price;
    map['job_price'] = jobPrice;
    map['provider_id'] = providerId;
    map['customer_id'] = customerId;
    map['status'] = status;
    map['customer_name'] = customerName;
    map['customer_profile'] = customerProfile;
    map['can_bid'] = canBid;
    map['created_at'] = createdAt;

    // 👇 Add new fields
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['address'] = address;
    map['expiry_days'] = expiryDays;
    map['request_type'] = requestType;

    if (service != null) {
      map['service'] = service?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  /// Check if the job has expired based on createdAt + expiryDays
  /// Returns true if the current date/time is after the expiry date
  bool get isExpired {
    if (expiryDays == null || createdAt == null || createdAt!.isEmpty) {
      return false;
    }

    try {
      // Parse the created date
      DateTime createdDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdAt!);
      
      // Calculate expiry date by adding expiryDays
      DateTime expiryDate = createdDate.add(Duration(days: expiryDays!));
      
      // Get current date/time
      DateTime now = DateTime.now();
      
      // Job is expired if current time is after or equal to expiry date
      return now.isAfter(expiryDate) || now.isAtSameMomentAs(expiryDate);
    } catch (e) {
      // If date parsing fails, log error and return false to be safe
      log('Error checking expiry: $e');
      return false;
    }
  }

  /// Get remaining days until expiry (returns 0 if expired or null if no expiry)
  int? get remainingDays {
    if (expiryDays == null || createdAt == null || createdAt!.isEmpty) {
      return null;
    }

    try {
      DateTime createdDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdAt!);
      DateTime expiryDate = createdDate.add(Duration(days: expiryDays!));
      DateTime now = DateTime.now();
      
      if (now.isAfter(expiryDate)) {
        return 0; // Expired
      }
      
      int days = expiryDate.difference(now).inDays;
      return days;
    } catch (e) {
      return null;
    }
  }
}
