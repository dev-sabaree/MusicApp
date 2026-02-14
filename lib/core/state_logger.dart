import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class StateLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('''
[StateLogger] Provider: "${provider.name ?? provider.runtimeType}"
  Old: $previousValue
  New: $newValue
''');
    }
  }
}
