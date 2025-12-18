import 'package:flutter_riverpod/flutter_riverpod.dart';

// Example simple provider
final exampleProvider = Provider<String>((ref) {
  return 'Hello from global provider';
});
