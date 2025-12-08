class CompanyModel {
  final String id;
  final String name;
  final String description;
  final String industry;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? province;
  final String? logoUrl;

  CompanyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.industry,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.province,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'industry': industry,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'province': province,
      'logoUrl': logoUrl,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      industry: map['industry'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      city: map['city'],
      province: map['province'],
      logoUrl: map['logoUrl'],
    );
  }
}

class CompanyInvitation {
  final String id;
  final String companyId;
  final String companyName;
  final String inviterId;
  final String inviteeId;
  final DateTime createdAt;
  final bool isAccepted;

  CompanyInvitation({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.inviterId,
    required this.inviteeId,
    required this.createdAt,
    this.isAccepted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'createdAt': createdAt,
      'isAccepted': isAccepted,
    };
  }

  factory CompanyInvitation.fromMap(Map<String, dynamic> map, String id) {
    return CompanyInvitation(
      id: id,
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      inviterId: map['inviterId'] ?? '',
      inviteeId: map['inviteeId'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isAccepted: map['isAccepted'] ?? false,
    );
  }
}