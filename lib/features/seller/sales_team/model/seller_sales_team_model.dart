class SellerSalesTeamResponse {
  final List<SellerSalesTeamMember> members;
  final SellerSalesTeamPagination pagination;

  const SellerSalesTeamResponse({
    required this.members,
    required this.pagination,
  });

  factory SellerSalesTeamResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerSalesTeamResponse(
      members: (data['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SellerSalesTeamMember.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerSalesTeamPagination.fromJson(data),
    );
  }
}

class SellerSalesTeamPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerSalesTeamPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerSalesTeamPagination.fromJson(Map<String, dynamic> json) {
    return SellerSalesTeamPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerSalesTeamEditData {
  final SellerSalesTeamMember member;
  final List<SellerSalesTeamLookup> cities;
  final List<SellerSalesTeamLookup> areas;

  const SellerSalesTeamEditData({
    required this.member,
    required this.cities,
    required this.areas,
  });

  factory SellerSalesTeamEditData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerSalesTeamEditData(
      member: SellerSalesTeamMember.fromJson(
        data['salesTeam'] is Map
            ? Map<String, dynamic>.from(data['salesTeam'])
            : <String, dynamic>{},
      ),
      cities: _lookups(data['cities']),
      areas: _lookups(data['areas']),
    );
  }
}

class SellerSalesTeamMember {
  final int id;
  final String uuid;
  final int userId;
  final int sellerId;
  final String picture;
  final String address;
  final int cityId;
  final int areaId;
  final String cityTitle;
  final String areaTitle;
  final String memberType;
  final String memberRole;
  final bool active;
  final String createdAt;
  final SellerSalesTeamUser user;

  const SellerSalesTeamMember({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.sellerId,
    required this.picture,
    required this.address,
    required this.cityId,
    required this.areaId,
    required this.cityTitle,
    required this.areaTitle,
    required this.memberType,
    required this.memberRole,
    required this.active,
    required this.createdAt,
    required this.user,
  });

  String get formattedCreatedAt => _date(createdAt);

  /// "Other, Lahore" — omits either part when unavailable.
  String get location {
    final a = areaTitle == 'Not available' ? '' : areaTitle;
    final c = cityTitle == 'Not available' ? '' : cityTitle;
    if (a.isNotEmpty && c.isNotEmpty) return '$a, $c';
    return a.isNotEmpty ? a : c;
  }

  factory SellerSalesTeamMember.fromJson(Map<String, dynamic> json) {
    final cityObj = json['city'];
    final areaObj = json['area'];
    return SellerSalesTeamMember(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      userId: _asInt(json['user_id']),
      sellerId: _asInt(json['seller_id']),
      picture: _text(json['picture']),
      address: _text(json['address']),
      cityId: _asInt(json['city_id']),
      areaId: _asInt(json['area_id']),
      cityTitle: cityObj is Map ? _text(cityObj['title']) : _text(cityObj),
      areaTitle: areaObj is Map ? _text(areaObj['title']) : _text(areaObj),
      memberType: _text(json['member_type'], fallback: 'sales'),
      memberRole: _text(json['member_role']),
      active: json['status']?.toString() == '1',
      createdAt: _text(json['created_at']),
      user: SellerSalesTeamUser.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerSalesTeamUser {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String joinedThrough;

  const SellerSalesTeamUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.joinedThrough,
  });

  factory SellerSalesTeamUser.fromJson(Map<String, dynamic> json) {
    return SellerSalesTeamUser(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      name: _text(json['name'], fallback: 'Team member'),
      email: _text(json['email']),
      phone: _text(json['phone']),
      role: _text(json['role']),
      status: _text(json['status']),
      joinedThrough: _text(json['joined_through']),
    );
  }
}

class SellerSalesTeamLookup {
  final int id;
  final String title;

  const SellerSalesTeamLookup({required this.id, required this.title});

  factory SellerSalesTeamLookup.fromJson(Map<String, dynamic> json) {
    return SellerSalesTeamLookup(
      id: _asInt(json['id']),
      title: _text(json['title'], fallback: 'Option'),
    );
  }
}

class SellerSalesTeamPerformance {
  final Map<String, String> metrics;

  const SellerSalesTeamPerformance({required this.metrics});

  factory SellerSalesTeamPerformance.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerSalesTeamPerformance(
      metrics: data.map((key, value) => MapEntry(key.toString(), _text(value))),
    );
  }
}

List<SellerSalesTeamLookup> _lookups(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            SellerSalesTeamLookup.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _text(dynamic value, {String fallback = 'Not available'}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

String _date(String value) {
  if (value.isEmpty || value == 'Not available') return 'N/A';
  try {
    final dt = DateTime.parse(value).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return value.split('T').first;
  }
}
