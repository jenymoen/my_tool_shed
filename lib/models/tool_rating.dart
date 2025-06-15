import 'package:cloud_firestore/cloud_firestore.dart';

class ToolRating {
  final String id;
  final String toolId;
  final String raterId;
  final String raterName;
  final String borrowerId;
  final String borrowerName;
  final double rating;
  final String? comment;
  final DateTime ratingDate;
  final bool isReturned;
  final bool isOnTime;
  final bool isInGoodCondition;

  ToolRating({
    required this.id,
    required this.toolId,
    required this.raterId,
    required this.raterName,
    required this.borrowerId,
    required this.borrowerName,
    required this.rating,
    this.comment,
    DateTime? ratingDate,
    this.isReturned = true,
    this.isOnTime = true,
    this.isInGoodCondition = true,
  }) : ratingDate = ratingDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toolId': toolId,
      'raterId': raterId,
      'raterName': raterName,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'rating': rating,
      'comment': comment,
      'ratingDate': Timestamp.fromDate(ratingDate),
      'isReturned': isReturned,
      'isOnTime': isOnTime,
      'isInGoodCondition': isInGoodCondition,
    };
  }

  factory ToolRating.fromMap(Map<String, dynamic> map) {
    return ToolRating(
      id: map['id'] as String,
      toolId: map['toolId'] as String,
      raterId: map['raterId'] as String,
      raterName: map['raterName'] as String,
      borrowerId: map['borrowerId'] as String,
      borrowerName: map['borrowerName'] as String,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String?,
      ratingDate: (map['ratingDate'] as Timestamp).toDate(),
      isReturned: map['isReturned'] as bool,
      isOnTime: map['isOnTime'] as bool,
      isInGoodCondition: map['isInGoodCondition'] as bool,
    );
  }
}
