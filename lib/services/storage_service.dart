import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user UID
import 'package:path/path.dart' as p; // For getting file extension

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Uploads an image file to Firebase Storage and returns the download URL.
  // Path will be: users/{uid}/tool_images/{toolId_or_fileName}.{extension}
  Future<String?> uploadToolImage(
      File imageFile, String toolIdOrFileName) async {
    if (currentUser == null) {
      throw Exception('User not logged in. Cannot upload image.');
    }
    try {
      final String userId = currentUser!.uid;
      final String fileExtension = p.extension(imageFile.path);
      // Use toolId or a unique ID for the filename if toolId is not yet available (e.g. during new tool creation)
      // For simplicity, let's assume toolIdOrFileName can be the tool's ID or a temp ID that becomes the tool's ID.
      final String fileName = '$toolIdOrFileName$fileExtension';
      final Reference storageRef =
          _storage.ref('users/$userId/tool_images/$fileName');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      // print('Firebase Storage Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Handle other errors
      // print('Error uploading image: $e');
      return null;
    }
  }

  // Deletes an image from Firebase Storage using its download URL.
  Future<void> deleteToolImage(String imageUrl) async {
    if (currentUser == null) {
      // print('User not logged in. Cannot delete image.');
      return;
    }
    if (imageUrl.isEmpty) {
      // print('Image URL is empty, cannot delete.');
      return;
    }
    try {
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } on FirebaseException catch (e) {
      // Handle errors, e.g., object not found, permission denied
      // print('Error deleting image from Firebase Storage: ${e.code} - ${e.message}');
      // Optionally re-throw or handle based on error type
      if (e.code == 'object-not-found') {
        // print('Image not found, maybe already deleted.');
      } else {
        // print('Could not delete image: $e');
      }
    } catch (e) {
      // print('Generic error deleting image: $e');
    }
  }

  // If you need to upload an image before the tool has a Firestore ID,
  // you might upload it with a temporary unique ID, get the URL,
  // then when the tool is saved to Firestore with its final ID,
  // you could potentially rename/move the file in Storage to match the toolId.
  // Or, just use the initial unique ID as the filename.
  // For simplicity, the current `uploadToolImage` uses `toolIdOrFileName` directly.
}
