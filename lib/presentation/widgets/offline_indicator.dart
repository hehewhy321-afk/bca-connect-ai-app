import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/services/connectivity_service.dart';

class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.wifi_square,
                size: 20,
                color: Colors.orange.shade900,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You are offline. Some features may be limited.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.cloud_off,
                size: 18,
                color: Colors.orange.shade700,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

// Compact version for AppBar
class OfflineIndicatorCompact extends ConsumerWidget {
  const OfflineIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 14,
            color: Colors.orange.shade900,
          ),
          const SizedBox(width: 6),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

// Snackbar notification when going offline/online
class ConnectivitySnackbar extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivitySnackbar({super.key, required this.child});

  @override
  ConsumerState<ConnectivitySnackbar> createState() => _ConnectivitySnackbarState();
}

class _ConnectivitySnackbarState extends ConsumerState<ConnectivitySnackbar> {
  bool? _previousState;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      next.whenData((isOnline) {
        if (_previousState != null && _previousState != isOnline) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isOnline ? Iconsax.wifi : Icons.cloud_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isOnline 
                          ? 'Back online! All features available.' 
                          : 'You are offline. Some features may be limited.',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: isOnline ? Colors.green : Colors.orange.shade700,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        _previousState = isOnline;
      });
    });

    return widget.child;
  }
}
