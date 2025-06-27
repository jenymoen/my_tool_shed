import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/models/tool_rating.dart';
import 'package:my_tool_shed/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _communityMembersCollection = 'community_members';
  final String _toolRatingsCollection = 'tool_ratings';

  // Community Member Operations
  Future<void> addCommunityMember(CommunityMember member) async {
    await _firestore
        .collection(_communityMembersCollection)
        .doc(member.id)
        .set(member.toMap());
  }

  Future<void> updateCommunityMember(CommunityMember member) async {
    try {
      // First check if the document exists in the users collection
      final userDoc = await _firestore.collection('users').doc(member.id).get();

      if (!userDoc.exists) {
        // If it doesn't exist in users collection, create it
        await _firestore
            .collection('users')
            .doc(member.id)
            .set(member.toFirestore());
      } else {
        // Update the user document
        await _firestore
            .collection('users')
            .doc(member.id)
            .update(member.toFirestore());
      }

      // Also ensure it exists in community_members collection
      final communityDoc = await _firestore
          .collection(_communityMembersCollection)
          .doc(member.id)
          .get();

      if (!communityDoc.exists) {
        // If it doesn't exist in community_members collection, create it
        await _firestore
            .collection(_communityMembersCollection)
            .doc(member.id)
            .set(member.toMap());
      } else {
        // Update the community member document
        await _firestore
            .collection(_communityMembersCollection)
            .doc(member.id)
            .update(member.toMap());
      }
    } catch (e) {
      AppLogger.error('Error updating community member', e, null);
      rethrow;
    }
  }

  Future<CommunityMember?> getCommunityMember(String memberId) async {
    final doc = await _firestore
        .collection(_communityMembersCollection)
        .doc(memberId)
        .get();
    if (doc.exists) {
      return CommunityMember.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<List<CommunityMember>> getCommunityMembers() {
    return _firestore.collection(_communityMembersCollection).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => CommunityMember.fromMap(doc.data()))
            .toList());
  }

  // Trust System Operations
  Future<void> addTrust(String fromUserId, String toUserId) async {
    final batch = _firestore.batch();

    // Get references to both documents
    final fromUserRef =
        _firestore.collection(_communityMembersCollection).doc(fromUserId);
    final toUserRef =
        _firestore.collection(_communityMembersCollection).doc(toUserId);

    // Check if documents exist and create them if they don't
    final fromUserDoc = await fromUserRef.get();
    final toUserDoc = await toUserRef.get();

    if (!fromUserDoc.exists) {
      // Create the fromUser document with all required fields
      batch.set(fromUserRef, {
        'id': fromUserId,
        'name': 'User $fromUserId', // Temporary name, should be updated later
        'trustedUsers': [],
        'trustedBy': [],
        'rating': 0.0,
        'totalRatings': 0,
        'joinedDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'toolsShared': 0,
        'toolsBorrowed': 0,
      });
    }

    if (!toUserDoc.exists) {
      // Create the toUser document with all required fields
      batch.set(toUserRef, {
        'id': toUserId,
        'name': 'User $toUserId', // Temporary name, should be updated later
        'trustedUsers': [],
        'trustedBy': [],
        'rating': 0.0,
        'totalRatings': 0,
        'joinedDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'toolsShared': 0,
        'toolsBorrowed': 0,
      });
    }

    // Add to trustedUsers list of fromUser
    batch.update(fromUserRef, {
      'trustedUsers': FieldValue.arrayUnion([toUserId])
    });

    // Add to trustedBy list of toUser
    batch.update(toUserRef, {
      'trustedBy': FieldValue.arrayUnion([fromUserId])
    });

    await batch.commit();
  }

  Future<void> removeTrust(String fromUserId, String toUserId) async {
    final batch = _firestore.batch();

    // Get references to both documents
    final fromUserRef =
        _firestore.collection(_communityMembersCollection).doc(fromUserId);
    final toUserRef =
        _firestore.collection(_communityMembersCollection).doc(toUserId);

    // Check if documents exist and create them if they don't
    final fromUserDoc = await fromUserRef.get();
    final toUserDoc = await toUserRef.get();

    if (!fromUserDoc.exists) {
      // Create the fromUser document with all required fields
      batch.set(fromUserRef, {
        'id': fromUserId,
        'name': 'User $fromUserId', // Temporary name, should be updated later
        'trustedUsers': [],
        'trustedBy': [],
        'rating': 0.0,
        'totalRatings': 0,
        'joinedDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'toolsShared': 0,
        'toolsBorrowed': 0,
      });
    }

    if (!toUserDoc.exists) {
      // Create the toUser document with all required fields
      batch.set(toUserRef, {
        'id': toUserId,
        'name': 'User $toUserId', // Temporary name, should be updated later
        'trustedUsers': [],
        'trustedBy': [],
        'rating': 0.0,
        'totalRatings': 0,
        'joinedDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'toolsShared': 0,
        'toolsBorrowed': 0,
      });
    }

    // Remove from trustedUsers list of fromUser
    batch.update(fromUserRef, {
      'trustedUsers': FieldValue.arrayRemove([toUserId])
    });

    // Remove from trustedBy list of toUser
    batch.update(toUserRef, {
      'trustedBy': FieldValue.arrayRemove([fromUserId])
    });

    await batch.commit();
  }

  // Tool Rating Operations
  Future<void> addToolRating(ToolRating rating) async {
    final batch = _firestore.batch();

    // Add the rating
    final ratingRef = _firestore.collection(_toolRatingsCollection).doc();
    batch.set(ratingRef, rating.toMap());

    // Update tool's community rating
    final toolRef = _firestore.collection('tools').doc(rating.toolId);
    batch.update(toolRef, {
      'totalCommunityRatings': FieldValue.increment(1),
      'communityRating': FieldValue.increment(rating.rating)
    });

    await batch.commit();
  }

  Stream<List<ToolRating>> getToolRatings(String toolId) {
    return _firestore
        .collection(_toolRatingsCollection)
        .where('toolId', isEqualTo: toolId)
        .orderBy('ratingDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ToolRating.fromMap(doc.data()))
            .toList());
  }

  // Tool Sharing Operations
  Future<void> updateToolSharingSettings(Tool tool) async {
    try {
      AppLogger.info('Starting tool sharing settings update...');
      AppLogger.debug('Tool ID: ${tool.id}');
      AppLogger.debug('Tool owner ID: ${tool.ownerId}');
      AppLogger.debug(
          'Current user ID: ${FirebaseAuth.instance.currentUser?.uid}');
      AppLogger.debug('Tool settings:');
      AppLogger.debug(
          '- isAvailableForCommunity: ${tool.isAvailableForCommunity}');
      AppLogger.debug('- requiresApproval: ${tool.requiresApproval}');
      AppLogger.debug('- allowedBorrowers: ${tool.allowedBorrowers}');

      // Get the tool from the user's tools collection
      final toolRef = _firestore
          .collection('users')
          .doc(tool.ownerId)
          .collection('tools')
          .doc(tool.id);

      // First verify the document exists
      final docSnapshot = await toolRef.get();
      if (!docSnapshot.exists) {
        AppLogger.error('Tool document does not exist', null, null);
        throw Exception('Tool document does not exist');
      }

      // Verify ownership
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        AppLogger.error('No authenticated user', null, null);
        throw Exception('You must be logged in to update tool settings');
      }

      if (tool.ownerId != currentUserId) {
        AppLogger.error(
            'Permission denied - user is not the owner', null, null);
        throw Exception('You do not have permission to update this tool');
      }

      AppLogger.info(
          'Document exists and user has permission, proceeding with update...');
      final updateData = tool.toFirestore();
      AppLogger.debug('Update data: $updateData');

      // Update the tool in the user's collection
      await toolRef.set(updateData, SetOptions(merge: true));
      AppLogger.info('Tool updated in user collection');

      // Also update the tool in the community tools collection
      final communityToolRef = _firestore.collection('tools').doc(tool.id);

      // If the tool is not available for community, delete it from the community collection
      if (!tool.isAvailableForCommunity) {
        try {
          await communityToolRef.delete();
          AppLogger.info('Tool removed from community collection');
        } catch (e) {
          AppLogger.error(
              'Error removing tool from community collection', e, null);
          throw Exception(
              'Failed to remove tool from community sharing: ${e.toString()}');
        }
      } else {
        // If the tool is available for community, update it in the community collection
        try {
          await communityToolRef.set(updateData, SetOptions(merge: true));
          AppLogger.info('Tool updated in community collection');
        } catch (e) {
          AppLogger.error(
              'Error updating tool in community collection', e, null);
          throw Exception(
              'Failed to update tool in community sharing: ${e.toString()}');
        }
      }

      // Verify the update
      final updatedDoc = await toolRef.get();
      final updatedData = updatedDoc.data();
      AppLogger.debug('Verification - Updated tool data:');
      AppLogger.debug(
          '- isAvailableForCommunity: ${updatedData?['isAvailableForCommunity']}');
      AppLogger.debug(
          '- requiresApproval: ${updatedData?['requiresApproval']}');
      AppLogger.debug(
          '- allowedBorrowers: ${updatedData?['allowedBorrowers']}');

      AppLogger.info('Tool sharing settings updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating tool sharing settings', e, stackTrace);
      if (e is FirebaseException) {
        AppLogger.error('Firebase error code: ${e.code}', null, null);
        AppLogger.error('Firebase error message: ${e.message}', null, null);
      }
      rethrow;
    }
  }

  Stream<List<Tool>> getCommunityTools() {
    AppLogger.info('Fetching community tools...');
    return _firestore
        .collection('tools')
        .where('isAvailableForCommunity', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      AppLogger.debug('Firestore snapshot received:');
      AppLogger.debug('Number of documents: ${snapshot.docs.length}');

      final tools = snapshot.docs.map((doc) {
        AppLogger.debug('Document ID: ${doc.id}');
        final data = doc.data();

        // Log the raw data
        AppLogger.debug('Raw document data:');
        AppLogger.debug('Data type: ${data.runtimeType}');
        AppLogger.debug('Data keys: ${data.keys.join(', ')}');
        AppLogger.debug('Data values: ${data.values.join(', ')}');
        AppLogger.debug('Image path: ${data['imagePath']}');

        // Add document ID to data
        data['documentId'] = doc.id;

        AppLogger.debug('Creating Tool from data: $data');
        final tool = Tool.fromMap(data);
        AppLogger.debug('Created Tool:');
        AppLogger.debug('- ID: ${tool.id}');
        AppLogger.debug('- Name: ${tool.name}');
        AppLogger.debug('- Brand: ${tool.brand}');
        AppLogger.debug('- Owner: ${tool.ownerName}');
        AppLogger.debug('- Rating: ${tool.communityRating}');
        AppLogger.debug('- Image Path: ${tool.imagePath}');
        return tool;
      }).toList();

      AppLogger.debug('Total tools created: ${tools.length}');
      return tools;
    });
  }

  // Tool Recommendations
  Stream<List<Tool>> getRecommendedTools(String userId) {
    return _firestore
        .collection(_communityMembersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return [];

      final user = CommunityMember.fromMap(userDoc.data()!);

      // Get tools from trusted members
      final trustedTools = await _firestore
          .collection('tools')
          .where('ownerId', whereIn: user.trustedUsers)
          .where('isAvailableForCommunity', isEqualTo: true)
          .orderBy('communityRating', descending: true)
          .limit(10)
          .get();

      return trustedTools.docs.map((doc) => Tool.fromMap(doc.data())).toList();
    });
  }

  Stream<CommunityMember> getMemberStream(String userId) {
    return _firestore
        .collection(_communityMembersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        // Return a default member if document doesn't exist
        return CommunityMember(
          id: userId,
          name: 'Unknown User',
          trustedBy: [],
          trustedUsers: [],
        );
      }
      return CommunityMember.fromFirestore(doc.data()!);
    });
  }
}
