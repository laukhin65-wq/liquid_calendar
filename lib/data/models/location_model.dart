class LocationModel {
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  const LocationModel({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      name: map['name'] ?? '',
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get mapUrl {
    if (latitude != null && longitude != null) {
      return 'https://maps.google.com/?q=$latitude,$longitude';
    }
    return 'https://maps.google.com/?q=${Uri.encodeComponent(name)}';
  }

  String get geoUri {
    if (latitude != null && longitude != null) {
      return 'geo:$latitude,$longitude?q=${Uri.encodeComponent(name)}';
    }
    return 'geo:0,0?q=${Uri.encodeComponent(name)}';
  }

  String toDisplayString() {
    final buf = StringBuffer('📍 $name');
    if (address != null && address!.isNotEmpty) {
      buf.write('\n$address');
    }
    if (latitude != null && longitude != null) {
      buf.write('\n$latitude, $longitude');
    }
    return buf.toString();
  }
}
