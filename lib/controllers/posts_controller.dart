import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostsController {
  static final PostsController _instance = PostsController._internal();

  PostsController._internal();

  factory PostsController() {
    return _instance;
  }

  Future<bool> addPost({required String postContent}) async {
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'publisherUserId': FirebaseAuth.instance.currentUser!.uid,
        'publisherUserName': FirebaseAuth.instance.currentUser!.displayName,
        'postContent': postContent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getPostsStream() {
    return FirebaseFirestore.instance.collection('posts').snapshots();
  }

  Future<bool> deletePost({required String postId}) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
