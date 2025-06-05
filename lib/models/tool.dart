// import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp
import 'package:my_tool_shed/utils/logger.dart';

class Tool {
  final String id;
  final String name;
  final String? imagePath;
  final String? brand;
  final bool isBorrowed;
  final DateTime? returnDate;
  final String? borrowedBy;
  final List<BorrowHistory> borrowHistory;
  final String? borrowerPhone;
  final String? borrowerEmail;
  final String? notes;
  final String? qrCode;
  final String? category;
  final bool isAvailableForCommunity;
  final List<String>
      allowedBorrowers; // List of user IDs who can borrow this tool
  final double communityRating;
  final int totalCommunityRatings;
  final String ownerId;
  final String ownerName;
  final bool requiresApproval;
  final String? location;
  final String? condition;
  final DateTime lastMaintenanceDate;
  final String? maintenanceNotes;

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
    this.isAvailableForCommunity = false,
    List<String>? allowedBorrowers,
    this.communityRating = 0.0,
    this.totalCommunityRatings = 0,
    required this.ownerId,
    required this.ownerName,
    this.requiresApproval = true,
    this.location,
    this.condition,
    DateTime? lastMaintenanceDate,
    this.maintenanceNotes,
  })  : borrowHistory = borrowHistory ?? [],
        allowedBorrowers = allowedBorrowers ?? [],
        lastMaintenanceDate = lastMaintenanceDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'brand': brand,
      'isBorrowed': isBorrowed,
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'borrowedBy': borrowedBy,
      'borrowHistory': borrowHistory.map((x) => x.toMap()).toList(),
      'borrowerPhone': borrowerPhone,
      'borrowerEmail': borrowerEmail,
      'notes': notes,
      'qrCode': qrCode,
      'category': category,
      'isAvailableForCommunity': isAvailableForCommunity,
      'allowedBorrowers': allowedBorrowers,
      'communityRating': communityRating,
      'totalCommunityRatings': totalCommunityRatings,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'requiresApproval': requiresApproval,
      'location': location,
      'condition': condition,
      'lastMaintenanceDate': Timestamp.fromDate(lastMaintenanceDate),
      'maintenanceNotes': maintenanceNotes,
    };
  }

  factory Tool.fromMap(Map<String, dynamic> map) {
    AppLogger.debug('Creating Tool from map:');
    AppLogger.debug('Map type: ${map.runtimeType}');
    AppLogger.debug('Map keys: ${map.keys.join(', ')}');
    AppLogger.debug('Map values: ${map.values.join(', ')}');

    // Check specific fields
    AppLogger.debug('name field: ${map['name']} (${map['name']?.runtimeType})');
    AppLogger.debug(
        'ownerId field: ${map['ownerId']} (${map['ownerId']?.runtimeType})');
    AppLogger.debug(
        'ownerName field: ${map['ownerName']} (${map['ownerName']?.runtimeType})');

    // Validate required fields
    if (map['name'] == null || map['name'].toString().isEmpty) {
      AppLogger.warning('Tool name is missing or empty');
    }
    if (map['ownerId'] == null || map['ownerId'].toString().isEmpty) {
      AppLogger.warning('Tool ownerId is missing or empty');
    }
    if (map['ownerName'] == null || map['ownerName'].toString().isEmpty) {
      AppLogger.warning('Tool ownerName is missing or empty');
    }

    return Tool(
      id: map['id'] as String? ?? map['documentId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Tool',
      imagePath: map['imagePath'] as String?,
      brand: map['brand'] as String?,
      isBorrowed: map['isBorrowed'] as bool? ?? false,
      returnDate: map['returnDate'] != null
          ? (map['returnDate'] as Timestamp).toDate()
          : null,
      borrowedBy: map['borrowedBy'] as String?,
      borrowHistory: List<BorrowHistory>.from(
          map['borrowHistory']?.map((x) => BorrowHistory.fromMap(x)) ?? []),
      borrowerPhone: map['borrowerPhone'] as String?,
      borrowerEmail: map['borrowerEmail'] as String?,
      notes: map['notes'] as String?,
      qrCode: map['qrCode'] as String?,
      category: map['category'] as String?,
      isAvailableForCommunity: map['isAvailableForCommunity'] as bool? ?? false,
      allowedBorrowers: List<String>.from(map['allowedBorrowers'] ?? []),
      communityRating: (map['communityRating'] as num?)?.toDouble() ?? 0.0,
      totalCommunityRatings: map['totalCommunityRatings'] as int? ?? 0,
      ownerId: map['ownerId'] as String? ?? 'unknown',
      ownerName: map['ownerName'] as String? ?? 'Unknown Owner',
      requiresApproval: map['requiresApproval'] as bool? ?? true,
      location: map['location'] as String?,
      condition: map['condition'] as String?,
      lastMaintenanceDate: map['lastMaintenanceDate'] != null
          ? (map['lastMaintenanceDate'] as Timestamp).toDate()
          : DateTime.now(),
      maintenanceNotes: map['maintenanceNotes'] as String?,
    );
  }

  Tool copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? brand,
    bool? isBorrowed,
    DateTime? returnDate,
    String? borrowedBy,
    List<BorrowHistory>? borrowHistory,
    String? borrowerPhone,
    String? borrowerEmail,
    String? notes,
    String? qrCode,
    String? category,
    bool? isAvailableForCommunity,
    List<String>? allowedBorrowers,
    double? communityRating,
    int? totalCommunityRatings,
    String? ownerId,
    String? ownerName,
    bool? requiresApproval,
    String? location,
    String? condition,
    DateTime? lastMaintenanceDate,
    String? maintenanceNotes,
  }) {
    return Tool(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      brand: brand ?? this.brand,
      isBorrowed: isBorrowed ?? this.isBorrowed,
      returnDate: returnDate ?? this.returnDate,
      borrowedBy: borrowedBy ?? this.borrowedBy,
      borrowHistory: borrowHistory ?? this.borrowHistory,
      borrowerPhone: borrowerPhone ?? this.borrowerPhone,
      borrowerEmail: borrowerEmail ?? this.borrowerEmail,
      notes: notes ?? this.notes,
      qrCode: qrCode ?? this.qrCode,
      category: category ?? this.category,
      isAvailableForCommunity:
          isAvailableForCommunity ?? this.isAvailableForCommunity,
      allowedBorrowers: allowedBorrowers ?? this.allowedBorrowers,
      communityRating: communityRating ?? this.communityRating,
      totalCommunityRatings:
          totalCommunityRatings ?? this.totalCommunityRatings,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      maintenanceNotes: maintenanceNotes ?? this.maintenanceNotes,
    );
  }

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
        'isAvailableForCommunity': isAvailableForCommunity,
        'allowedBorrowers': allowedBorrowers,
        'communityRating': communityRating,
        'totalCommunityRatings': totalCommunityRatings,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'requiresApproval': requiresApproval,
        'location': location,
        'condition': condition,
        'lastMaintenanceDate': Timestamp.fromDate(lastMaintenanceDate),
        'maintenanceNotes': maintenanceNotes,
      };

  factory Tool.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return Tool(
      id: snapshot.id, // Get ID from DocumentSnapshot
      name: data['name'] as String? ?? '',
      imagePath: data['imagePath'] as String?,
      brand: data['brand'] as String?,
      isBorrowed: data['isBorrowed'] as bool? ?? false,
      returnDate: data['returnDate'] == null
          ? null
          : (data['returnDate'] as Timestamp).toDate(),
      borrowedBy: data['borrowedBy'] as String?,
      // borrowHistory will be loaded separately from its subcollection
      borrowerPhone: data['borrowerPhone'] as String?,
      borrowerEmail: data['borrowerEmail'] as String?,
      notes: data['notes'] as String?,
      qrCode: data['qrCode'] as String?,
      category: data['category'] as String?,
      isAvailableForCommunity:
          data['isAvailableForCommunity'] as bool? ?? false,
      allowedBorrowers: List<String>.from(data['allowedBorrowers'] ?? []),
      communityRating: (data['communityRating'] as num?)?.toDouble() ?? 0.0,
      totalCommunityRatings: data['totalCommunityRatings'] as int? ?? 0,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      requiresApproval: data['requiresApproval'] as bool? ?? true,
      location: data['location'] as String?,
      condition: data['condition'] as String?,
      lastMaintenanceDate: data['lastMaintenanceDate'] != null
          ? (data['lastMaintenanceDate'] as Timestamp).toDate()
          : DateTime.now(),
      maintenanceNotes: data['maintenanceNotes'] as String?,
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

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory BorrowHistory.fromMap(Map<String, dynamic> map) {
    return BorrowHistory(
      id: map['id'] as String,
      borrowerId: map['borrowerId'] as String,
      borrowerName: map['borrowerName'] as String,
      borrowerPhone: map['borrowerPhone'] as String?,
      borrowerEmail: map['borrowerEmail'] as String?,
      borrowDate: DateTime.parse(map['borrowDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      returnDate: map['returnDate'] == null
          ? null
          : DateTime.parse(map['returnDate'] as String),
      notes: map['notes'] as String?,
    );
  }

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
