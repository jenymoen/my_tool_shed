// import 'package:flutter/foundation.dart';

class Tool {
  String id;
  String name;
  String? imagePath;
  String? brand;
  bool isBorrowed;
  DateTime? returnDate;
  String? borrowedBy;
  List<BorrowHistory> borrowHistory;
  String? borrowerPhone;
  String? borrowerEmail;
  String? notes;
  String? qrCode;
  String? category;

  Tool({
    required this.id,
    required this.name,
    this.imagePath,
    this.brand,
    this.isBorrowed = false,
    this.returnDate,
    this.borrowedBy,
    List<BorrowHistory>? borrowHistory,
    this.borrowerPhone,
    this.borrowerEmail,
    this.notes,
    this.qrCode,
    this.category,
  }) : borrowHistory = borrowHistory ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'brand': brand,
        'isBorrowed': isBorrowed,
        'returnDate': returnDate?.toIso8601String(),
        'borrowedBy': borrowedBy,
        'borrowHistory': borrowHistory.map((h) => h.toJson()).toList(),
        'borrowerPhone': borrowerPhone,
        'borrowerEmail': borrowerEmail,
        'notes': notes,
        'qrCode': qrCode,
        'category': category,
      };

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String?,
        brand: json['brand'] as String?,
        isBorrowed: json['isBorrowed'] as bool,
        returnDate: json['returnDate'] == null
            ? null
            : DateTime.parse(json['returnDate'] as String),
        borrowedBy: json['borrowedBy'] as String?,
        borrowHistory: (json['borrowHistory'] as List<dynamic>?)
                ?.map((e) => BorrowHistory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        borrowerPhone: json['borrowerPhone'] as String?,
        borrowerEmail: json['borrowerEmail'] as String?,
        notes: json['notes'] as String?,
        qrCode: json['qrCode'] as String?,
        category: json['category'] as String?,
      );
}

class BorrowHistory {
  final String id;
  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final String? borrowerEmail;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String? notes;

  BorrowHistory({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    this.borrowerPhone,
    this.borrowerEmail,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'borrowerId': borrowerId,
        'borrowerName': borrowerName,
        'borrowerPhone': borrowerPhone,
        'borrowerEmail': borrowerEmail,
        'borrowDate': borrowDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'notes': notes,
      };

  factory BorrowHistory.fromJson(Map<String, dynamic> json) => BorrowHistory(
        id: json['id'] as String,
        borrowerId: json['borrowerId'] as String,
        borrowerName: json['borrowerName'] as String,
        borrowerPhone: json['borrowerPhone'] as String?,
        borrowerEmail: json['borrowerEmail'] as String?,
        borrowDate: DateTime.parse(json['borrowDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        returnDate: json['returnDate'] == null
            ? null
            : DateTime.parse(json['returnDate'] as String),
        notes: json['notes'] as String?,
      );
}
