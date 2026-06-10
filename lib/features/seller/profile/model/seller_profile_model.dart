class SellerProfileBundle {
  final SellerProfileUser profile;
  final SellerProfileSeller sellerInfo;
  final SellerBusinessInfo businessInfo;

  const SellerProfileBundle({
    required this.profile,
    required this.sellerInfo,
    required this.businessInfo,
  });
}

class SellerProfileUser {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String joinedThrough;
  final String lastLoginAt;
  final SellerProfileSeller seller;
  final String? profilePictureUrl;

  const SellerProfileUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.joinedThrough,
    required this.lastLoginAt,
    required this.seller,
    this.profilePictureUrl,
  });

  factory SellerProfileUser.fromResponse(Map<String, dynamic> response) {
    final outer = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};

    // Handle both: combined payload (data.user) and direct user payload (data)
    final data = outer['user'] is Map
        ? Map<String, dynamic>.from(outer['user'])
        : outer;

    final pictureUrl = data['profile_picture_url']?.toString().trim();

    return SellerProfileUser(
      id: _asInt(data['id']),
      uuid: _text(data['uuid']),
      name: _text(data['name'], fallback: 'Seller'),
      email: _text(data['email']),
      phone: _text(data['phone']),
      role: _text(data['role'], fallback: 'seller'),
      status: _text(data['status'], fallback: 'Unknown'),
      joinedThrough: _text(data['joined_through']),
      lastLoginAt: _date(data['last_login_at']),
      seller: SellerProfileSeller.fromJson(
        data['seller'] is Map
            ? Map<String, dynamic>.from(data['seller'])
            : (outer['seller'] is Map
                ? Map<String, dynamic>.from(outer['seller'])
                : <String, dynamic>{}),
      ),
      profilePictureUrl: (pictureUrl == null || pictureUrl.isEmpty || pictureUrl == 'null')
          ? null
          : pictureUrl,
    );
  }
}

class SellerProfileSeller {
  final int id;
  final String code;
  final String name;
  final String businessName;
  final String cnicNumber;
  final String website;
  final int cityId;
  final String cityTitle;
  final String address;
  final String investmentCapacity;
  final String previousExperience;
  final String whatsappPhone;
  final String businessType;
  final String businessPhone;
  final String ntnTax;
  final String fulfillment;
  final String feedback;
  final String feeChargeType;
  final String feeChargeValue;
  final bool verified;
  final bool topRated;
  final String updatedAt;
  final List<SellerLookupOption> activeAreas;

  const SellerProfileSeller({
    required this.id,
    required this.code,
    required this.name,
    required this.businessName,
    required this.cnicNumber,
    required this.website,
    required this.cityId,
    required this.cityTitle,
    required this.address,
    required this.investmentCapacity,
    required this.previousExperience,
    required this.whatsappPhone,
    required this.businessType,
    required this.businessPhone,
    required this.ntnTax,
    required this.fulfillment,
    required this.feedback,
    required this.feeChargeType,
    required this.feeChargeValue,
    required this.verified,
    required this.topRated,
    required this.updatedAt,
    required this.activeAreas,
  });

  factory SellerProfileSeller.fromResponse(Map<String, dynamic> response) {
    final outer = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};

    final json = outer['seller'] is Map
        ? Map<String, dynamic>.from(outer['seller'])
        : outer;

    final rawAreas = outer['active_areas'];
    final cityObj = json['city'];

    return SellerProfileSeller(
      id: _asInt(json['id']),
      code: _text(json['code']),
      name: _text(json['name'], fallback: 'Seller'),
      businessName: _text(json['business_name'], fallback: 'Business'),
      cnicNumber: _text(json['cnic_number']),
      website: _text(json['website']),
      cityId: _asInt(json['city_id']),
      cityTitle: cityObj is Map ? _text(cityObj['title']) : _text(cityObj),
      address: _text(json['address']),
      investmentCapacity: _text(json['investment_capacity']),
      previousExperience: _text(json['previous_experience']),
      whatsappPhone: _text(json['whatsapp_phone']),
      businessType: _text(json['business_type']),
      businessPhone: _text(json['business_phone']),
      ntnTax: _text(json['ntn_tax']),
      fulfillment: _text(json['fulfillment']),
      feedback: _text(json['feedback']),
      feeChargeType: _text(json['fee_charge_type']),
      feeChargeValue: _text(json['fee_charge_value']),
      verified: json['verified']?.toString() == '1',
      topRated: json['top_rated']?.toString() == '1',
      updatedAt: _date(json['updated_at']),
      activeAreas: _options(rawAreas),
    );
  }

  factory SellerProfileSeller.fromJson(Map<String, dynamic> json) {
    final cityObj = json['city'];
    return SellerProfileSeller(
      id: _asInt(json['id']),
      code: _text(json['code']),
      name: _text(json['name'], fallback: 'Seller'),
      businessName: _text(json['business_name'], fallback: 'Business'),
      cnicNumber: _text(json['cnic_number']),
      website: _text(json['website']),
      cityId: _asInt(json['city_id']),
      cityTitle: cityObj is Map ? _text(cityObj['title']) : _text(cityObj),
      address: _text(json['address']),
      investmentCapacity: _text(json['investment_capacity']),
      previousExperience: _text(json['previous_experience']),
      whatsappPhone: _text(json['whatsapp_phone']),
      businessType: _text(json['business_type']),
      businessPhone: _text(json['business_phone']),
      ntnTax: _text(json['ntn_tax']),
      fulfillment: _text(json['fulfillment']),
      feedback: _text(json['feedback']),
      feeChargeType: _text(json['fee_charge_type']),
      feeChargeValue: _text(json['fee_charge_value']),
      verified: json['verified']?.toString() == '1',
      topRated: json['top_rated']?.toString() == '1',
      updatedAt: _date(json['updated_at']),
      activeAreas: const [],
    );
  }
}

class SellerBusinessInfo {
  final List<SellerLookupOption> cities;
  final List<SellerLookupOption> areas;
  final int sellerCityId;
  final List<int> sellerAreaIds;

  const SellerBusinessInfo({
    required this.cities,
    required this.areas,
    required this.sellerCityId,
    required this.sellerAreaIds,
  });

  factory SellerBusinessInfo.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};

    return SellerBusinessInfo(
      cities: _options(data['cities']),
      areas: _options(data['areas']),
      sellerCityId: _asInt(data['sellerCityId']),
      sellerAreaIds: _intList(data['sellerAreaIds']),
    );
  }

  String cityTitle(int cityId) {
    return cities
            .where((item) => item.id == cityId)
            .map((item) => item.title)
            .cast<String?>()
            .firstOrNull ??
        (cityId == 0 ? 'Not selected' : 'City #$cityId');
  }

  List<String> selectedAreaTitles() {
    final ids = sellerAreaIds.toSet();
    final titles = areas
        .where((item) => ids.contains(item.id))
        .map((item) => item.title)
        .toList(growable: false);
    if (titles.isEmpty) return const ['Not selected'];
    return titles;
  }
}

class SellerLookupOption {
  final int id;
  final String title;

  const SellerLookupOption({required this.id, required this.title});

  factory SellerLookupOption.fromJson(Map<String, dynamic> json) {
    return SellerLookupOption(
      id: _asInt(json['id']),
      title: _text(json['title'], fallback: 'Option'),
    );
  }
}

List<SellerLookupOption> _options(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => SellerLookupOption.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

List<int> _intList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_asInt).where((item) => item > 0).toList(growable: false);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value, {String fallback = 'Not available'}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

String _date(dynamic value) {
  final text = _text(value);
  if (text == 'Not available') return text;
  try {
    final dt = DateTime.parse(text).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return text.split('T').first;
  }
}
