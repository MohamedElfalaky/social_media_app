import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  static final AuthController _instance = AuthController._internal();

  factory AuthController() {
    return _instance;
  }

  AuthController._internal();

  Future<AuthResponse> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      var userCredentials = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredentials.user != null) {
        await userCredentials.user!.updateDisplayName(username);

        await userCredentials.user!.sendEmailVerification();

        await addUserToUsersCollection(
          mail: email,
          userName: username,
          userID: userCredentials.user!.uid,
        );
        return AuthResponse(success: true, message: 'Registration successful');
      } else {
        return AuthResponse(success: false, message: 'Registration failed');
      }
    } on FirebaseAuthException catch (e) {
      log('Error during registration: ${e.message}');

      return AuthResponse(success: false, message: e.message);
    } catch (e) {
      log('Something went wrong');

      return AuthResponse(success: false, message: 'Something went wrong');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      var userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        return AuthResponse(success: true, message: 'Sign in successful');
      } else {
        return AuthResponse(success: false, message: 'Sign in failed');
      }
    } on FirebaseAuthException catch (e) {
      log('Error during sign in: ${e.message}');
      return AuthResponse(success: false, message: e.message);
    } catch (e) {
      log('Something went wrong');
      return AuthResponse(success: false, message: 'Something went wrong');
    }
  }

  Future<AuthResponse> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      return AuthResponse(success: true, message: 'Sign out successful');
    } catch (e) {
      log('Error during sign out: $e');
      return AuthResponse(success: false, message: 'Error during sign out');
    }
  }

  Future<void> addUserToUsersCollection({
    required String mail,
    required String userName,
    required String userID,
    String? imgUrl,
    int? mobileNumber,
  }) async {
    await FirebaseFirestore.instance.collection('users').add({
      "imgUrl": imgUrl ?? "",
      "mail": mail,
      "mobileNumber": mobileNumber ?? 0,
      "userID": userID,
      "userName": userName,
    });
  }
}

class AuthResponse {
  final bool success;
  final String? message;

  AuthResponse({required this.success, this.message});
}
