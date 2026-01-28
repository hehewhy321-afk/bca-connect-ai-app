import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/resource.dart';
import '../../../data/repositories/resource_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/connectivity_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../../core/constants/easter_eggs.dart';
import '../../widgets/easter_egg_widget.dart';

// Provider for all resources
final allResourcesProvider = FutureProvider<List<Resource>>((ref) async {
  final repo = ResourceRepository();
  return await repo.getResources();
});

// State providers for filters
final resourceSearchQueryProvider = StateProvider<String>((ref) => '');
final resourceSelectedTypeProvider = StateProvider<String>((ref) => 'all');
final resourceSelectedSemesterProvider = StateProvider<String>((ref) => 'all');

// Filtered resources provider
final filteredResourcesProvider = Provider<AsyncValue<List<Resource>>>((ref) {
  final resourcesAsync = ref.watch(allResourcesProvider);
  final searchQuery = ref.watch(resourceSearchQueryProvider).toLowerCase();
  final selectedType = ref.watch(resourceSelectedTypeProvider);
  final selectedSemester = ref.watch(resourceSelectedSemesterProvider);

  return resourcesAsync.whenData((resources) {
    return resources.where((resource) {
      final matchesSearch = resource.title.toLowerCase().contains(searchQuery) ||
          (resource.description?.toLowerCase().contains(searchQuery) ?? false) ||
          (resource.subject?.toLowerCase().contains(searchQuery) ?? false);
      final matchesType = selectedType == 'all' || resource.type.toLowerCase() == selectedType.toLowerCase();
      final matchesSemester = selectedSemester == 'all' ||
          (resource.semester?.toString() == selectedSemester);
      return matchesSearch && matchesType && matchesSemester;
    }).toList();
  });
});

class EnhancedResourcesScreen extends ConsumerStatefulWidget {
  const EnhancedResourcesScreen({super.key});

  @override
  ConsumerState<EnhancedResourcesScreen> createState() => _EnhancedResourcesScreenState();
}

class _EnhancedResourcesScreenState extends ConsumerState<EnhancedResourcesScreen> {
  final Map<String, double> _downloadProgress = {};

  Future<void> _handleResourceView(BuildContext context, Resource resource) async {
    try {
      // Check connectivity first
      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isOnline();
      
      if (!isOnline) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.wifi_square, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('No Internet Connection')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleResourceView(context, resource),
              ),
            ),
          );
        }
        return;
      }

      final user = SupabaseConfig.client.auth.currentUser;

      // Increment view count
      await SupabaseConfig.client
          .from('resources')
          .update({'views': resource.views + 1}).eq('id', resource.id);

      // Track download if user is authenticated
      if (user != null) {
        try {
          await SupabaseConfig.client.from('resource_downloads').insert({
            'resource_id': resource.id,
            'user_id': user.id,
          });

          // Increment downloads count
          await SupabaseConfig.client
              .from('resources')
              .update({'downloads': resource.downloads + 1}).eq('id', resource.id);
        } catch (e) {
          if (!e.toString().contains('duplicate')) {
            debugPrint('Error tracking download: $e');
          }
        }
      }

      // Determine if it's a file or external link
      String? url = resource.externalUrl ?? resource.fileUrl;
      
      if (url == null) {
        throw 'No URL available for this resource';
      }

      // Check if it's an external link (not a file)
      if (resource.externalUrl != null && resource.fileUrl == null) {
        // It's an external link - open in browser
        await _openInBrowser(url);
      } else {
        // It's a file - download it
        if (!context.mounted) return;
        await _downloadFile(context, resource, url);
      }

      // Refresh resources to get updated counts
      ref.invalidate(allResourcesProvider);
    } catch (e) {
      if (context.mounted) {
        String errorMessage;
        Color errorColor = Colors.red;
        IconData errorIcon = Iconsax.close_circle;
        
        final errorString = e.toString();
        if (errorString.contains('No internet connection') || 
            errorString.contains('SocketException') ||
            errorString.contains('Failed host lookup')) {
          errorMessage = 'No internet connection. Please check your network.';
          errorIcon = Iconsax.wifi_square;
          errorColor = Colors.orange;
        } else if (errorString.contains('Storage permission')) {
          errorMessage = 'Storage permission required to download files.';
          errorIcon = Iconsax.folder_minus;
          errorColor = Colors.blue;
        } else if (errorString.contains('Could not launch')) {
          errorMessage = 'Unable to open this link. Please try again.';
          errorIcon = Iconsax.link_21;
          errorColor = Colors.orange;
        } else if (errorString.contains('No URL available')) {
          errorMessage = 'This resource is not available for download.';
          errorIcon = Iconsax.info_circle;
          errorColor = Colors.blue;
        } else {
          errorMessage = 'Unable to access this resource. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: errorString.contains('No internet connection') || errorString.contains('try again')
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _handleResourceView(context, resource),
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _openInBrowser(String url) async {
    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _downloadFile(BuildContext context, Resource resource, String url) async {
    try {
      // Check connectivity before starting download
      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isOnline();
      
      if (!isOnline) {
        throw 'No internet connection available for download';
      }

      // Request storage permission for Android
      if (Platform.isAndroid) {
        PermissionStatus status;
        
        // For Android 13+ (API 33+), we need different permissions
        if (await Permission.photos.isPermanentlyDenied || 
            await Permission.videos.isPermanentlyDenied ||
            await Permission.audio.isPermanentlyDenied) {
          // Show dialog to open settings
          if (context.mounted) {
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Storage Permission Required'),
                content: const Text(
                  'This app needs storage permission to download files. Please grant permission in settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
            
            if (shouldOpenSettings == true) {
              await openAppSettings();
            }
          }
          return;
        }
        
        // Try to request storage permission
        status = await Permission.storage.request();
        
        // If denied, try manageExternalStorage for Android 11+
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        
        // If still denied, show dialog
        if (!status.isGranted) {
          if (context.mounted) {
            final shouldRetry = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Storage Permission Required'),
                content: const Text(
                  'To download files, we need access to your device storage. Would you like to grant permission?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            );
            
            if (shouldRetry == true) {
              // Try again or open settings if permanently denied
              if (status.isPermanentlyDenied) {
                await openAppSettings();
              } else {
                status = await Permission.manageExternalStorage.request();
                if (!status.isGranted) {
                  throw 'Storage permission is required to download files';
                }
              }
            } else {
              return;
            }
          } else {
            throw 'Storage permission denied';
          }
        }
      }

      // Get the proper file URL from Supabase
      String downloadUrl = url;
      if (url.contains('/storage/v1/object/') || url.startsWith('resources/')) {
        String filePath = url;
        if (url.contains('/storage/v1/object/public/')) {
          filePath = url.split('/storage/v1/object/public/').last;
        }
        
        final parts = filePath.split('/');
        if (parts.length >= 2) {
          final bucket = parts[0];
          final path = parts.sublist(1).join('/');
          downloadUrl = SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
        }
      }

      // Extract file extension from URL
      String fileName = resource.title;
      final urlParts = downloadUrl.split('/');
      final lastPart = urlParts.last.split('?').first;
      if (lastPart.contains('.')) {
        final extension = lastPart.split('.').last;
        if (!fileName.endsWith('.$extension')) {
          fileName = '$fileName.$extension';
        }
      }

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try to use public Downloads folder first
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          // Fallback to app-specific directory
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw 'Could not access storage directory';
      }

      final filePath = '${directory.path}/$fileName';

      // Show downloading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Downloading...')),
              ],
            ),
            duration: const Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      // Download file with timeout and error handling
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[resource.id] = received / total;
            });
          }
        },
      );

      setState(() {
        _downloadProgress.remove(resource.id);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Download Complete!', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Saved to: ${directory.path.contains('Download') ? 'Downloads' : 'App Storage'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final uri = Uri.file(filePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Error opening file: $e');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(resource.id);
      });
      
      // Handle specific download errors
      String errorMessage;
      if (e.toString().contains('No internet connection')) {
        errorMessage = 'No internet connection available for download';
      } else if (e.toString().contains('DioException') || e.toString().contains('timeout')) {
        errorMessage = 'Download failed due to network timeout. Please try again.';
      } else if (e.toString().contains('Storage permission')) {
        errorMessage = 'Storage permission required to download files';
      } else if (e.toString().contains('Could not access storage')) {
        errorMessage = 'Unable to access device storage for download';
      } else {
        errorMessage = 'Download failed. Please check your connection and try again.';
      }
      
      throw errorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredResourcesAsync = ref.watch(filteredResourcesProvider);
    final searchQuery = ref.watch(resourceSearchQueryProvider);
    final selectedType = ref.watch(resourceSelectedTypeProvider);
    final selectedSemester = ref.watch(resourceSelectedSemesterProvider);

    final types = [
      'all',
      'study_material',
      'past_paper',
      'project',
      'interview_prep',
      'article'
    ];

    final semesters = ['all', '1', '2', '3', '4', '5', '6', '7', '8'];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: EasterEggWidget(
          soundFile: EasterEggs.resources.soundFile,
          emoji: EasterEggs.resources.emoji,
          message: EasterEggs.resources.message,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resource Hub', style: TextStyle(fontSize: 20)),
              Text(
                'Study materials & resources',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allResourcesProvider);
        },
        child: Column(
          children: [
            // Search Bar with Semester Filter Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => ref.read(resourceSearchQueryProvider.notifier).state = value,
                      decoration: InputDecoration(
                        hintText: 'Search resources...',
                        prefixIcon: const Icon(Iconsax.search_normal_1),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Iconsax.close_circle),
                                onPressed: () => ref.read(resourceSearchQueryProvider.notifier).state = '',
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Semester Filter Button
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: selectedSemester != 'all'
                              ? const LinearGradient(
                                  colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                                )
                              : null,
                          color: selectedSemester != 'all' ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Iconsax.calendar,
                            color: selectedSemester != 'all' ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => _showSemesterModal(context, ref, semesters),
                        ),
                      ),
                      if (selectedSemester != 'all')
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Resource Type Filter Pills
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: types.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = types[index];
                  final isSelected = selectedType == type;
                  return FilterChip(
                    label: Text(_formatType(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(resourceSelectedTypeProvider.notifier).state = type;
                    },
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: ModernTheme.primaryOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: BorderSide(
                        color: isSelected
                            ? ModernTheme.primaryOrange
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? ModernTheme.primaryOrange
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Resources List
            Expanded(
              child: filteredResourcesAsync.when(
                data: (resources) {
                  if (resources.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.folder_open,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No resources found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: resources.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _ResourceCard(
                        resource: resources[index],
                        onTap: () => _handleResourceView(context, resources[index]),
                        downloadProgress: _downloadProgress[resources[index].id],
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: 6,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => const ResourceCardSkeleton(),
                ),
                error: (error, stack) {
                  // Check if it's a network error
                  final isNetworkError = error.toString().contains('No internet connection') ||
                      error.toString().contains('SocketException') ||
                      error.toString().contains('Failed host lookup');

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isNetworkError ? Iconsax.wifi_square : Iconsax.danger,
                          size: 64,
                          color: isNetworkError
                              ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isNetworkError ? 'No Internet Connection' : 'Error loading resources',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            isNetworkError
                                ? 'Please check your internet connection and try again'
                                : 'Something went wrong. Please try again',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => ref.invalidate(allResourcesProvider),
                          icon: const Icon(Iconsax.refresh),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ModernTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    if (type == 'all') return 'All Types';
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  void _showSemesterModal(BuildContext context, WidgetRef ref, List<String> semesters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use local state variable
        String localSemester = ref.read(resourceSelectedSemesterProvider);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.calendar, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter by Semester',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Iconsax.close_circle),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Semester Section
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: semesters.map((semester) {
                          final isSelected = localSemester == semester;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                localSemester = semester;
                              });
                              ref.read(resourceSelectedSemesterProvider.notifier).state = semester;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                                      )
                                    : null,
                                color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                semester == 'all' ? 'All Semesters' : 'Sem $semester',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  localSemester = 'all';
                                });
                                ref.read(resourceSelectedSemesterProvider.notifier).state = 'all';
                              },
                              icon: const Icon(Iconsax.refresh),
                              label: const Text('Clear Filter'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Apply',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Resource Card Widget - Completely Redesigned
class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;
  final double? downloadProgress;

  const _ResourceCard({
    required this.resource,
    required this.onTap,
    this.downloadProgress,
  });

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'study_material':
        return Iconsax.book_1;
      case 'past_paper':
        return Iconsax.document_text_1;
      case 'project':
        return Iconsax.code_circle;
      case 'interview_prep':
        return Iconsax.briefcase;
      case 'article':
        return Iconsax.note_1;
      default:
        return Iconsax.document;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'study_material':
        return const Color(0xFF0A6B62);
      case 'past_paper':
        return const Color(0xFF0A6B62);
      case 'project':
        return const Color(0xFF3B82F6);
      case 'interview_prep':
        return const Color(0xFFEC4899);
      case 'article':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  LinearGradient _getGradientForType(String type) {
    switch (type.toLowerCase()) {
      case 'study_material':
        return const LinearGradient(
          colors: [Color.fromARGB(255, 6, 53, 49), Color.fromARGB(255, 36, 34, 7)],
        );
      case 'past_paper':
        return const LinearGradient(
          colors: [Color.fromARGB(255, 7, 54, 50), Color.fromARGB(255, 65, 79, 9)],
        );
      case 'project':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        );
      case 'interview_prep':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        );
      case 'article':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Color(0xFF9CA3AF)],
        );
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  bool _isExternalLink() {
    return resource.externalUrl != null && resource.fileUrl == null;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(resource.type);
    final gradient = _getGradientForType(resource.type);
    final isExternal = _isExternalLink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: downloadProgress == null ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon and Type Badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _getIconForType(resource.type),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              _formatType(resource.type),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                isExternal ? Iconsax.link : Iconsax.document_download,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isExternal ? 'External Link' : 'Downloadable',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      resource.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    if (resource.description != null)
                      Text(
                        resource.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 16),

                    // Tags Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (resource.semester != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.calendar, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  'Semester ${resource.semester}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (resource.subject != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.book, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  resource.subject!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats and Action Button
                    Row(
                      children: [
                        // Stats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.eye, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${resource.views}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Iconsax.document_download, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${resource.downloads}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Action Button
                        if (downloadProgress != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    value: downloadProgress,
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(downloadProgress! * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDA7809).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExternal ? Iconsax.export_1 : Iconsax.document_download,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isExternal ? 'Open Link' : 'Download',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
