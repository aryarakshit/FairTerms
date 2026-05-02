/// Model representing an SME business profile.
library;

/// Represents the data for creating or viewing an SME profile.
class SmeProfile {
  final String? profileId;
  final String businessName;
  final String ownerName;
  final String pincode;
  final String city;
  final String state;
  final String industry;
  final int annualRevenueInr;
  final int employeeCount;
  final int yearsInOperation;
  final String? gstNumber;
  final String? phoneNumber;
  final String? photoUrl;
  final String? createdAt;

  const SmeProfile({
    this.profileId,
    required this.businessName,
    required this.ownerName,
    required this.pincode,
    required this.city,
    required this.state,
    required this.industry,
    required this.annualRevenueInr,
    required this.employeeCount,
    required this.yearsInOperation,
    this.gstNumber,
    this.phoneNumber,
    this.photoUrl,
    this.createdAt,
  });

  /// Creates an [SmeProfile] from a JSON map.
  factory SmeProfile.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return SmeProfile(
      profileId: json['profile_id'] as String?,
      businessName: (json['business_name'] as String?) ?? '',
      ownerName: (json['owner_name'] as String?) ?? '',
      pincode: (json['pincode'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      industry: (json['industry'] as String?) ?? '',
      annualRevenueInr: toInt(json['annual_revenue_inr']),
      employeeCount: toInt(json['employee_count']),
      yearsInOperation: toInt(json['years_in_operation']),
      gstNumber: json['gst_number'] as String?,
      phoneNumber: json['phone_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] is String ? json['created_at'] as String : null,
    );
  }

  /// Converts this [SmeProfile] to a JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      if (profileId != null) 'profile_id': profileId,
      'business_name': businessName,
      'owner_name': ownerName,
      'pincode': pincode,
      'city': city,
      'state': state,
      'industry': industry,
      'annual_revenue_inr': annualRevenueInr,
      'employee_count': employeeCount,
      'years_in_operation': yearsInOperation,
      if (gstNumber != null) 'gst_number': gstNumber,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  /// Creates a copy of this profile with updated fields.
  SmeProfile copyWith({
    String? profileId,
    String? businessName,
    String? ownerName,
    String? pincode,
    String? city,
    String? state,
    String? industry,
    int? annualRevenueInr,
    int? employeeCount,
    int? yearsInOperation,
    String? gstNumber,
    String? phoneNumber,
    String? photoUrl,
    String? createdAt,
  }) {
    return SmeProfile(
      profileId: profileId ?? this.profileId,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      industry: industry ?? this.industry,
      annualRevenueInr: annualRevenueInr ?? this.annualRevenueInr,
      employeeCount: employeeCount ?? this.employeeCount,
      yearsInOperation: yearsInOperation ?? this.yearsInOperation,
      gstNumber: gstNumber ?? this.gstNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
