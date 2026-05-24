class Owner {
  final int id;
  final String ownerName;
  final String email;
  final String contactNumber;

  Owner({
    required this.id,
    required this.ownerName,
    required this.email,
    required this.contactNumber,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      ownerName: json['ownerName'] ?? '',
      email: json['email'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerName': ownerName,
      'email': email,
      'contactNumber': contactNumber,
    };
  }
}

class Field {
  int? id;
  String name;
  String address;
  String? type;
  String? facilities;
  double pricePerHour;
  double? _rating;
  String? openingTime;
  String? closingTime;
  String? grassType;
  double? length;
  double? width;
  bool? available;
  bool? outdoor;
  Owner? owner;
  String? imageUrl;
  double? latitude;
  double? longitude;
  double? distance; // Khoảng cách từ vị trí hiện tại (km)

  Field({
    this.id,
    required this.name,
    required this.address,
    this.type,
    this.facilities,
    required this.pricePerHour,
    double? rating,
    this.openingTime,
    this.closingTime,
    this.grassType,
    this.length,
    this.width,
    this.available,
    this.outdoor,
    this.owner,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.distance,
  }) : _rating = rating;

  factory Field.fromJson(Map<String, dynamic> json){
    return Field(
      id: json['id'],
      name: json['name'] ?? "",
      address: json['address'] ?? "",
      type: json['type'],
      facilities: json['facilities'],
      pricePerHour: (json['pricePerHour'] is num) ? json['pricePerHour'].toDouble() : 0,
      rating: (json['rating'] is num)
        ? json['rating'].toDouble()
        : (json['rating'] != null ? double.tryParse(json['rating'].toString()) : null),
      openingTime: json['openingTime']?.toString(),
      closingTime: json['closingTime']?.toString(),
      grassType: json['grassType'],
      length: (json['length'] is num) ? json['length'].toDouble() : (json['length'] != null ? double.tryParse(json['length'].toString()) : null),
      width: (json['width'] is num) ? json['width'].toDouble() : (json['width'] != null ? double.tryParse(json['width'].toString()) : null),
      available: json['available'] is bool ? json['available'] : (json['available'] == 1 || json['available'] == 'true'),
      outdoor: json['outdoor'] is bool ? json['outdoor'] : (json['outdoor'] == 1 || json['outdoor'] == 'true'),
      owner: json['owner'] != null ? Owner.fromJson(json['owner']) : null,
      imageUrl: json['imageUrl'],
      latitude: (json['latitude'] is num) ? json['latitude'].toDouble() : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null),
      longitude: (json['longitude'] is num) ? json['longitude'].toDouble() : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null),
    );
  }

  get rating => _rating;

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'address': address,
      'type': type,
      'facilities': facilities,
      'pricePerHour': pricePerHour,
      'rating': _rating,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'grassType': grassType,
      'length': length,
      'width': width,
      'available': available,
      'outdoor': outdoor,
      'owner': owner?.toJson(),
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
