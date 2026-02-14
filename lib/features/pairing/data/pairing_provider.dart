import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/repositories/mock_pairing_repository.dart';

class PairingState {
  final PairingStatus status;
  final String? code;
  final bool isLoading;
  final String? error;

  PairingState({
    this.status = PairingStatus.none,
    this.code,
    this.isLoading = false,
    this.error,
  });
}

class PairingController extends StateNotifier<PairingState> {
  final PairingRepository _repository;

  PairingController(this._repository) : super(PairingState());

  Future<void> generateCode() async {
    state = PairingState(isLoading: true);
    try {
      final code = await _repository.generateCode();
      state = PairingState(status: PairingStatus.waiting, code: code);
    } catch (e) {
      state = PairingState(error: e.toString());
    }
  }

  Future<void> joinRoom(String code) async {
    state = PairingState(isLoading: true);
    try {
      final success = await _repository.joinRoom(code);
      if (success) {
        state = PairingState(status: PairingStatus.paired);
      } else {
        state = PairingState(error: "Invalid Code");
      }
    } catch (e) {
      state = PairingState(error: e.toString());
    }
  }
  
  void unpair() {
    state = PairingState(status: PairingStatus.none);
  }
}

final pairingControllerProvider = StateNotifierProvider<PairingController, PairingState>((ref) {
  return PairingController(ref.watch(pairingRepositoryProvider));
});
