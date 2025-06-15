import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user UID
import 'package:path/path.dart' as p; // For getting file extension
import 'package:my_tool_shed/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  StorageService() {
    // Validate storage bucket configuration
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    if (storageBucket == null || storageBucket.isEmpty) {
      AppLogger.error('Firebase Storage bucket is not configured', null, null);
      throw Exception(
          'Firebase Storage bucket is not configured. Please check your .env file.');
    }
    AppLogger.info('Using Firebase Storage bucket: $storageBucket');
  }

  // Uploads an image file to Firebase Storage and returns the download URL.
  // Path will be: users/{uid}/tool_images/{toolId_or_fileName}.{extension}
  Future<String?> uploadToolImage(
      File imageFile, String toolIdOrFileName) async {
    if (currentUser == null) {
      AppLogger.error('User not logged in. Cannot upload image.', null, null);
      throw Exception('User not logged in. Cannot upload image.');
    }
    try {
      final String userId = currentUser!.uid;
      AppLogger.info('Current user ID: $userId');

      final String fileExtension = p.extension(imageFile.path);
      final String fileName = '$toolIdOrFileName$fileExtension';
      final String storagePath = 'users/$userId/tool_images/$fileName';

      AppLogger.info('Attempting to upload image to path: $storagePath');
      AppLogger.debug('File path: ${imageFile.path}');
      AppLogger.debug('File exists: ${await imageFile.exists()}');
      AppLogger.debug('File size: ${await imageFile.length()} bytes');

      // Create storage reference with just the path
      final Reference storageRef = _storage.ref(storagePath);

      // Set metadata to ensure proper content type
      final metadata = SettableMetadata(
        contentType: 'image/${fileExtension.replaceAll('.', '')}',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.info('Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error(
          'Failed to upload image to Firebase Storage', e, stackTrace);
      AppLogger.error('Error code: ${e.code}');
      AppLogger.error('Error message: ${e.message}');
      AppLogger.error('Error details: ${e.toString()}');
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error while uploading image', e, stackTrace);
      throw Exception('Failed to upload image: $e');
    }
  }

  // Deletes an image from Firebase Storage using its download URL.
  Future<void> deleteToolImage(String imageUrl) async {
    if (currentUser == null || imageUrl.isEmpty) {
      return;
    }
    try {
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } on FirebaseException {
      // Silently handle Firebase errors
    }
  }

  // If you need to upload an image before the tool has a Firestore ID,
  // you might upload it with a temporary unique ID, get the URL,
  // then when the tool is saved to Firestore with its final ID,
  // you could potentially rename/move the file in Storage to match the toolId.
  // Or, just use the initial unique ID as the filename.
  // For simplicity, the current `uploadToolImage` uses `toolIdOrFileName` directly.
}
