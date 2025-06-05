import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_tool_shed/models/tool.dart'; // Will be updated later

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // --- Helper to get user-specific tools collection ---
  CollectionReference<Tool> _userToolsCollection() {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in for Firestore operations');
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('tools')
        .withConverter<Tool>(
          fromFirestore: Tool.fromFirestore,
          toFirestore: (Tool tool, options) => tool.toFirestore(),
        );
  }

  // --- Tool Methods ---

  // Stream to get all tools for the current user
  Stream<List<Tool>> getToolsStream() {
    return _userToolsCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Add a new tool
  Future<String> addTool(Tool tool) async {
    // Firestore will auto-generate an ID if we use .add()
    final docRef = await _userToolsCollection().add(tool);
    return docRef.id;
  }

  // Update an existing tool
  Future<void> updateTool(Tool tool) async {
    if (tool.id.isEmpty) {
      throw Exception('Tool ID cannot be empty for update operation');
    }
    return _userToolsCollection().doc(tool.id).update(tool.toFirestore());
  }

  // Delete a tool
  Future<void> deleteTool(String toolId) async {
    if (toolId.isEmpty) {
      throw Exception('Tool ID cannot be empty for delete operation');
    }
    // Note: This does not delete subcollections (like borrowHistory) by default.
    // We'll need to handle subcollection deletion separately if required.
    return _userToolsCollection().doc(toolId).delete();
  }

  // --- Borrow History Methods (subcollection of tools) ---

  CollectionReference<BorrowHistory> _borrowHistoryCollection(String toolId) {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in for Firestore operations');
    }
    if (toolId.isEmpty) {
      throw Exception('Tool ID cannot be empty for borrow history operations');
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('tools')
        .doc(toolId)
        .collection('borrowHistory')
        .withConverter<BorrowHistory>(
          fromFirestore: BorrowHistory.fromFirestore,
          toFirestore: (BorrowHistory history, options) =>
              history.toFirestore(),
        );
  }

  Stream<List<BorrowHistory>> getBorrowHistoryStream(String toolId) {
    return _borrowHistoryCollection(toolId)
        .orderBy('borrowDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> addBorrowHistory(String toolId, BorrowHistory history) async {
    // Firestore will auto-generate an ID for the history entry.
    await _borrowHistoryCollection(toolId).add(history);
  }

  Future<void> updateBorrowHistory(String toolId, BorrowHistory history) async {
    if (history.id.isEmpty) {
      throw Exception('BorrowHistory ID cannot be empty for update operation');
    }
    return _borrowHistoryCollection(toolId)
        .doc(history.id)
        .update(history.toFirestore());
  }

  Future<void> deleteBorrowHistoryEntry(String toolId, String historyId) async {
    if (historyId.isEmpty) {
      throw Exception('BorrowHistory ID cannot be empty for delete operation');
    }
    return _borrowHistoryCollection(toolId).doc(historyId).delete();
  }

  // Helper to delete all borrow history for a tool (e.g., when deleting a tool)
  Future<void> deleteAllBorrowHistoryForTool(String toolId) async {
    final snapshot = await _borrowHistoryCollection(toolId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
