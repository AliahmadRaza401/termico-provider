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

    if (service != null) {
      map['service'] = service?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
