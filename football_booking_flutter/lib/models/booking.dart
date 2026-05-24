import 'field.dart';
import 'user.dart';

class Booking {
  int? id;
  Field field;
  DateTime fromTime;
  DateTime toTime;
  String? additional;
  String? customerName;
  String? customerPhone;
  User? customer;
  String? fieldName;

  Booking({
    this.id,
    required this.field,
    required this.fromTime,
    required this.toTime,
    this.additional,
    this.customerName,
    this.customerPhone,
    this.customer,
    this.fieldName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      field: Field.fromJson(json['field'] ?? {}),
      fromTime: DateTime.parse(json['fromTime'] ?? json['from'] ?? DateTime.now().toIso8601String()),
      toTime: DateTime.parse(json['toTime'] ?? json['to'] ?? DateTime.now().toIso8601String()),
      additional: json['additional'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customer: json['customer'] != null ? User.fromJson(json['customer']) : null,
      fieldName: json['fieldName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field.toJson(),
      'fromTime': fromTime.toIso8601String(),
      'toTime': toTime.toIso8601String(),
      if (additional != null) 'additional': additional,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customer != null) 'customer': customer!.toJson(),
    };
  }

  String get formattedFromTime {
    return "${fromTime.day}/${fromTime.month}/${fromTime.year} ${fromTime.hour}:${fromTime.minute}";
  }

  String get formattedToTime {
    return "${toTime.day}/${toTime.month}/${toTime.year} ${toTime.hour}:${toTime.minute}";
  }
}

