class UserModel {
  final String id;
  final String name;
  final String email;
  final String? birthdate;
  final String? location;
  final String? phoneNumber;
  final String? bio;
  final String? profilePicUrl;
  final bool isWorkingAtCompany;
  final String? companyName;
  final String? position;
  final String? buildingNumber;
  final String? address;
  final String? careerStartDate;
  final String? idNumber;
  final String? companyPicUrl;
  final bool isActive;
  final bool profileCompleted;
  final bool useCompanyName;
  final bool isCompanyMode;
  final String? activeCompanyId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.birthdate,
    this.location,
    this.phoneNumber,
    this.bio,
    this.profilePicUrl,
    this.isWorkingAtCompany = false,
    this.companyName,
    this.position,
    this.buildingNumber,
    this.address,
    this.careerStartDate,
    this.idNumber,
    this.companyPicUrl,
    this.isActive = true,
    this.profileCompleted = false,
    this.useCompanyName = true,
    this.isCompanyMode = false,
    this.activeCompanyId,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    String name = map['name'] ?? '';
    if (name.isEmpty && (map['firstName'] != null || map['lastName'] != null)) {
      final firstName = map['firstName'] ?? '';
      final lastName = map['lastName'] ?? '';
      name = '$firstName $lastName'.trim();
    }
    
    return UserModel(
      id: id,
      name: name,
      email: map['email'] ?? '',
      birthdate: map['birthdate'],
      location: map['location'] ?? map['address'],
      phoneNumber: map['phoneNumber'],
      bio: map['bio'],
      profilePicUrl: map['profilePicUrl'],
      isWorkingAtCompany: map['isWorkingAtCompany'] ?? false,
      companyName: map['companyName'],
      position: map['position'],
      buildingNumber: map['buildingNumber'],
      address: map['address'],
      careerStartDate: map['careerStartDate'],
      idNumber: map['idNumber'],
      companyPicUrl: map['companyPicUrl'],
      isActive: map['isActive'] ?? true,
      profileCompleted: map['profileCompleted'] ?? false,
      useCompanyName: map['useCompanyName'] ?? false,
      isCompanyMode: map['isCompanyMode'] ?? false,
      activeCompanyId: map['activeCompanyId'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'birthdate': birthdate,
      'location': location,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'isWorkingAtCompany': isWorkingAtCompany,
      'companyName': companyName,
      'position': position,
      'buildingNumber': buildingNumber,
      'address': address,
      'careerStartDate': careerStartDate,
      'idNumber': idNumber,
      'companyPicUrl': companyPicUrl,
      'isActive': isActive,
      'profileCompleted': profileCompleted,
      'useCompanyName': useCompanyName,
      'isCompanyMode': isCompanyMode,
      'activeCompanyId': activeCompanyId,
      'createdAt': createdAt,
    };
  }
}