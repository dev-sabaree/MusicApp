import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/ui/custom_loading.dart';
import 'package:music_app/features/pairing/data/pairing_provider.dart';

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

    ref.listen<PairingState>(pairingControllerProvider, (previous, next) {
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair with your partner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Host Session'),
            Tab(text: 'Join Session'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.18),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_tethering_rounded, size: 70),
                      const SizedBox(height: 14),
                      const Text('Create your couple room'),
                      const SizedBox(height: 16),
                      if (pairingState.code != null) ...[
                        Text(
                          pairingState.code!,
                          style: theme.textTheme.displaySmall?.copyWith(
                            letterSpacing: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: pairingState.code!));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code copied!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy code'),
                            ),
                            const SizedBox(width: 10),
                            if (pairingState.isLoading) const CustomLoadingIndicator(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Waiting for your partner to join...'),
                      ] else
                        ElevatedButton.icon(
                          onPressed: pairingState.isLoading
                              ? null
                              : () => ref.read(pairingControllerProvider.notifier).generateCode(),
                          icon: pairingState.isLoading
                              ? const SizedBox(width: 18, height: 18, child: CustomLoadingIndicator())
                              : const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Generate Pairing Code'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    child: Column(
                      children: [
                        const Text('Enter your partner\'s 4-digit code'),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Pairing code',
                            hintText: '1234',
                            counterText: '',
                          ),
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: pairingState.isLoading
                        ? null
                        : () => ref.read(pairingControllerProvider.notifier).joinRoom(_codeController.text.trim()),
                    icon: pairingState.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CustomLoadingIndicator())
                        : const Icon(Icons.link_rounded),
                    label: const Text('Join now'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
