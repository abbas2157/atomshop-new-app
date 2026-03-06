// network_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_manager.dart';

// This provider allows you to access the singleton NetworkManager.
final networkManagerProvider = Provider<NetworkManager>((ref) {
  return NetworkManager.create();
});
