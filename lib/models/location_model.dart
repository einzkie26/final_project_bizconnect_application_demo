class LocationModel {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  LocationModel({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      displayName: map['display_name'] ?? '',
      latitude: double.tryParse(map['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(map['lon']?.toString() ?? '0') ?? 0.0,
      city: map['address']?['city'],
      country: map['address']?['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'address': {
        'city': city,
        'country': country,
      },
    };
  }
}