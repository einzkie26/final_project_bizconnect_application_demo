class ProfileSetupModel {
  final String? phoneNumber;
  final String? profilePicUrl;
  final String? bio;
  final bool isWorkingAtCompany;
  final String? companyName;
  final String? position;

  ProfileSetupModel({
    this.phoneNumber,
    this.profilePicUrl,
    this.bio,
    this.isWorkingAtCompany = false,
    this.companyName,
    this.position,
  });

  ProfileSetupModel copyWith({
    String? phoneNumber,
    String? profilePicUrl,
    String? bio,
    bool? isWorkingAtCompany,
    String? companyName,
    String? position,
  }) {
    return ProfileSetupModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bio: bio ?? this.bio,
      isWorkingAtCompany: isWorkingAtCompany ?? this.isWorkingAtCompany,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'profilePicUrl': profilePicUrl,
      'bio': bio,
      'isWorkingAtCompany': isWorkingAtCompany,
      'companyName': companyName,
      'position': position,
    };
  }
}