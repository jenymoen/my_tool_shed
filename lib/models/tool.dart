// import 'package:flutter/foundation.dart';

class Tool {
  String id;
  String name;
  String? imagePath;
  bool isBorrowed;
  DateTime? returnDate;
  String? borrowedBy;

  Tool({
    required this.id,
    required this.name,
    this.imagePath,
    this.isBorrowed = false,
    this.returnDate,
    this.borrowedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'isBorrowed': isBorrowed,
        'returnDate': returnDate?.toIso8601String(),
        'borrowedBy': borrowedBy,
      };

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String?,
        isBorrowed: json['isBorrowed'] as bool,
        returnDate: json['returnDate'] == null
            ? null
            : DateTime.parse(json['returnDate'] as String),
        borrowedBy: json['borrowedBy'] as String?,
      );
}
