import 'field.dart';

class Favorite {
  int? id;
  int? customerId;
  Field field;

  Favorite({this.id, this.customerId, required this.field});

  factory Favorite.fromJson(Map<String, dynamic> json){
    return Favorite(
      id: json['id'],
      customerId: json['customerId'],
      field: Field.fromJson(json['field']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'field': field.toJson(),
    };
  }
}
