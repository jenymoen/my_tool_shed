// import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp

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

  // Firestore conversion
  Map<String, dynamic> toFirestore() => {
        // id is document ID, not stored in fields
        'name': name,
        'imagePath': imagePath,
        'brand': brand,
        'isBorrowed': isBorrowed,
        'returnDate':
            returnDate == null ? null : Timestamp.fromDate(returnDate!),
        'borrowedBy': borrowedBy,
        // borrowHistory will be a subcollection, not stored directly in the tool document
        'borrowerPhone': borrowerPhone,
        'borrowerEmail': borrowerEmail,
        'notes': notes,
        'qrCode': qrCode,
        'category': category,
      };

  factory Tool.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options) {
    final data = snapshot.data();
    return Tool(
      id: snapshot.id, // Get ID from DocumentSnapshot
      name: data?['name'] as String,
      imagePath: data?['imagePath'] as String?,
      brand: data?['brand'] as String?,
      isBorrowed: data?['isBorrowed'] as bool,
      returnDate: data?['returnDate'] == null
          ? null
          : (data?['returnDate'] as Timestamp).toDate(),
      borrowedBy: data?['borrowedBy'] as String?,
      // borrowHistory will be loaded separately from its subcollection
      borrowerPhone: data?['borrowerPhone'] as String?,
      borrowerEmail: data?['borrowerEmail'] as String?,
      notes: data?['notes'] as String?,
      qrCode: data?['qrCode'] as String?,
      category: data?['category'] as String?,
      borrowHistory: [], // Initialize as empty, will be populated from subcollection
    );
  }
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

  // Firestore conversion
  Map<String, dynamic> toFirestore() => {
        // id is document ID for subcollection, not stored in fields
        'borrowerId':
            borrowerId, // This might be the user ID or a unique ID for the borrower instance
        'borrowerName': borrowerName,
        'borrowerPhone': borrowerPhone,
        'borrowerEmail': borrowerEmail,
        'borrowDate': Timestamp.fromDate(borrowDate),
        'dueDate': Timestamp.fromDate(dueDate),
        'returnDate':
            returnDate == null ? null : Timestamp.fromDate(returnDate!),
        'notes': notes,
      };

  factory BorrowHistory.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options) {
    final data = snapshot.data();
    return BorrowHistory(
      id: snapshot.id, // Get ID from DocumentSnapshot
      borrowerId: data?['borrowerId'] as String,
      borrowerName: data?['borrowerName'] as String,
      borrowerPhone: data?['borrowerPhone'] as String?,
      borrowerEmail: data?['borrowerEmail'] as String?,
      borrowDate: (data?['borrowDate'] as Timestamp).toDate(),
      dueDate: (data?['dueDate'] as Timestamp).toDate(),
      returnDate: data?['returnDate'] == null
          ? null
          : (data?['returnDate'] as Timestamp).toDate(),
      notes: data?['notes'] as String?,
    );
  }
}
