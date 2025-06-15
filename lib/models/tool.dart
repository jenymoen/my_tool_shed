// import 'package:flutter/foundation.dart';

class Tool {
  String id;
  String name;
  String? imagePath;
  bool isBorrowed;
  DateTime? returnDate;
  String? borrowedBy;
  List<BorrowHistory> borrowHistory;
  String? borrowerPhone;
  String? borrowerEmail;
  String? notes;
  String? qrCode;
  String? category;
  int maintenanceInterval; // in days
  DateTime? lastMaintenance;

  Tool({
    required this.id,
    required this.name,
    this.imagePath,
    this.isBorrowed = false,
    this.returnDate,
    this.borrowedBy,
    List<BorrowHistory>? borrowHistory,
    this.borrowerPhone,
    this.borrowerEmail,
    this.notes,
    this.qrCode,
    this.category,
    this.maintenanceInterval = 0,
    this.lastMaintenance,
  }) : borrowHistory = borrowHistory ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'isBorrowed': isBorrowed,
        'returnDate': returnDate?.toIso8601String(),
        'borrowedBy': borrowedBy,
        'borrowHistory': borrowHistory.map((h) => h.toJson()).toList(),
        'borrowerPhone': borrowerPhone,
        'borrowerEmail': borrowerEmail,
        'notes': notes,
        'qrCode': qrCode,
        'category': category,
        'maintenanceInterval': maintenanceInterval,
        'lastMaintenance': lastMaintenance?.toIso8601String(),
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
        borrowHistory: (json['borrowHistory'] as List<dynamic>?)
                ?.map((e) => BorrowHistory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        borrowerPhone: json['borrowerPhone'] as String?,
        borrowerEmail: json['borrowerEmail'] as String?,
        notes: json['notes'] as String?,
        qrCode: json['qrCode'] as String?,
        category: json['category'] as String?,
        maintenanceInterval: json['maintenanceInterval'] as int? ?? 0,
        lastMaintenance: json['lastMaintenance'] == null
            ? null
            : DateTime.parse(json['lastMaintenance'] as String),
      );

  bool needsMaintenance() {
    if (maintenanceInterval == 0 || lastMaintenance == null) return false;
    final daysUntilMaintenance = lastMaintenance!
        .add(Duration(days: maintenanceInterval))
        .difference(DateTime.now())
        .inDays;
    return daysUntilMaintenance <= 0;
  }

  int daysUntilMaintenance() {
    if (maintenanceInterval == 0 || lastMaintenance == null) return -1;
    return lastMaintenance!
        .add(Duration(days: maintenanceInterval))
        .difference(DateTime.now())
        .inDays;
  }
}

class BorrowHistory {
  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final String? borrowerEmail;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String? notes;

  BorrowHistory({
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
