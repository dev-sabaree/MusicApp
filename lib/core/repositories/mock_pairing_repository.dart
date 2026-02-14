import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PairingStatus { none, waiting, paired }

class PairingRepository {
  Future<String> generateCode() async {
    await Future.delayed(const Duration(seconds: 1));
    return "1234"; // Fixed code for demo
  }

  Future<bool> joinRoom(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    if (code == "1234") {
      return true;
    }
    return false;
  }
}

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return PairingRepository();
});
