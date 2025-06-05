import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMember {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final double rating;
  final int totalRatings;
  final List<String> trustedBy; // List of user IDs who trust this member
  final List<String> trustedUsers; // List of user IDs this member trusts
  final DateTime joinedDate;
  final bool isActive;
  final String? address;
  final String? bio;
  final int toolsShared;
  final int toolsBorrowed;

  CommunityMember({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.rating = 0.0,
    this.totalRatings = 0,
    List<String>? trustedBy,
    List<String>? trustedUsers,
    DateTime? joinedDate,
    this.isActive = true,
    this.address,
    this.bio,
    this.toolsShared = 0,
    this.toolsBorrowed = 0,
  })  : trustedBy = trustedBy ?? [],
        trustedUsers = trustedUsers ?? [],
        joinedDate = joinedDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'rating': rating,
      'totalRatings': totalRatings,
      'trustedBy': trustedBy,
      'trustedUsers': trustedUsers,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'isActive': isActive,
      'address': address,
      'bio': bio,
      'toolsShared': toolsShared,
      'toolsBorrowed': toolsBorrowed,
    };
  }

  factory CommunityMember.fromMap(Map<String, dynamic> map) {
    return CommunityMember(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      rating: (map['rating'] as num).toDouble(),
      totalRatings: map['totalRatings'] as int,
      trustedBy: List<String>.from(map['trustedBy'] ?? []),
      trustedUsers: List<String>.from(map['trustedUsers'] ?? []),
      joinedDate: (map['joinedDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool,
      address: map['address'] as String?,
      bio: map['bio'] as String?,
      toolsShared: (map['toolsShared'] as num?)?.toInt() ?? 0,
      toolsBorrowed: (map['toolsBorrowed'] as num?)?.toInt() ?? 0,
    );
  }

  CommunityMember copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    double? rating,
    int? totalRatings,
    List<String>? trustedBy,
    List<String>? trustedUsers,
    DateTime? joinedDate,
    bool? isActive,
    String? address,
    String? bio,
    int? toolsShared,
    int? toolsBorrowed,
  }) {
    return CommunityMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      trustedBy: trustedBy ?? this.trustedBy,
      trustedUsers: trustedUsers ?? this.trustedUsers,
      joinedDate: joinedDate ?? this.joinedDate,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      toolsShared: toolsShared ?? this.toolsShared,
      toolsBorrowed: toolsBorrowed ?? this.toolsBorrowed,
    );
  }

  factory CommunityMember.fromFirestore(Map<String, dynamic> data) {
    return CommunityMember(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      trustedBy: List<String>.from(data['trustedBy'] ?? []),
      trustedUsers: List<String>.from(data['trustedUsers'] ?? []),
      joinedDate: (data['joinedDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool,
      address: data['address'] as String?,
      bio: data['bio'] as String?,
      toolsShared: (data['toolsShared'] as num?)?.toInt() ?? 0,
      toolsBorrowed: (data['toolsBorrowed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'rating': rating,
      'totalRatings': totalRatings,
      'trustedBy': trustedBy,
      'trustedUsers': trustedUsers,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'isActive': isActive,
      'address': address,
      'bio': bio,
      'toolsShared': toolsShared,
      'toolsBorrowed': toolsBorrowed,
    };
  }
}
