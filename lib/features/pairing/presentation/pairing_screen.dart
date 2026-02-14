import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/pairing/data/pairing_provider.dart';
import 'package:music_app/core/repositories/mock_pairing_repository.dart';
import 'package:music_app/core/ui/custom_loading.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairingState = ref.watch(pairingControllerProvider);
    final theme = Theme.of(context);

    // Error handling
    ref.listen(pairingControllerProvider, (previous, next) {
        if (next.error != null && !next.isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
          );
        }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Music'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Host'),
            Tab(text: 'Join'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // HOST TAB
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pairingState.code != null) ...[
                  Text('Your Pairing Code', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 16),
                  Text(
                    pairingState.code!,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Waiting for partner to join...'),
                ] else ...[
                   Icon(Icons.wifi_tethering, size: 80, color: theme.colorScheme.secondary),
                   const SizedBox(height: 24),
                   const Text(
                     'Create a room to listen together', 
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 32),
                   ElevatedButton.icon(
                      onPressed: pairingState.isLoading 
                          ? null 
                          : () => ref.read(pairingControllerProvider.notifier).generateCode(),
                      icon: pairingState.isLoading 
                          ? const CustomLoadingIndicator() 
                          : const Icon(Icons.add),
                      label: const Text('Generate Code'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                   ),
                ],
              ],
            ),
          ),
          
          // JOIN TAB
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 const Text(
                   'Enter the code shown on your partner\'s screen',
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 32),
                 TextField(
                   controller: _codeController,
                   decoration: const InputDecoration(
                     labelText: 'Pairing Code',
                     hintText: 'e.g. 1234',
                     border: OutlineInputBorder(),
                     counterText: '',
                   ),
                   maxLength: 4,
                   keyboardType: TextInputType.number,
                   textAlign: TextAlign.center,
                   style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
                 ),
                 const SizedBox(height: 32),
                 FilledButton.icon(
                   onPressed: pairingState.isLoading 
                       ? null 
                       : () => ref.read(pairingControllerProvider.notifier).joinRoom(_codeController.text),
                   icon: pairingState.isLoading 
                          ? const CustomLoadingIndicator() 
                          : const Icon(Icons.link),
                   label: const Text('Connect'),
                   style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
