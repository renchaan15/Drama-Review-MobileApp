class FirebaseService {
  // Singleton pattern (simple)
  FirebaseService._privateConstructor();
  static final FirebaseService instance = FirebaseService._privateConstructor();

  Future<void> init() async {
    // TODO: Initialize Firebase here (Firebase.initializeApp).
  }
}
