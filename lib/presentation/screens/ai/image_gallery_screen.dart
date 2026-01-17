import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/cached_image.dart';
import 'package:intl/intl.dart';

// Smart image widget that handles both base64 and URL images for fast loading
class SmartImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SmartImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data
        final base64Data = imageUrl.split(',')[1];
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      }
    }
    
    // It's a URL, use CachedImage
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius ?? BorderRadius.zero,
      errorWidget: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}

class ImageGalleryScreen extends ConsumerStatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  ConsumerState<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends ConsumerState<ImageGalleryScreen> {
  List<GeneratedImage> _images = [];
  List<GeneratedImage> _filteredImages = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedModel = 'all';
  String _sortBy = 'newest';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('ai_generated_images')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _images = (response as List)
            .map((json) => GeneratedImage.fromJson(json))
            .toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading images: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = _images.where((image) {
      final matchesSearch = image.prompt.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesModel = _selectedModel == 'all' || image.modelUsed?.contains(_selectedModel) == true;
      return matchesSearch && matchesModel;
    }).toList();

    // Sort
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    setState(() {
      _filteredImages = filtered;
    });
  }

  List<String> _getUniqueModels() {
    final models = _images
        .where((img) => img.modelUsed != null)
        .map((img) => img.modelUsed!)
        .toSet()
        .toList();
    return models;
  }

  String _parseModelName(String? modelUsed) {
    if (modelUsed == null) return 'Unknown';
    final parts = modelUsed.split(':');
    if (parts.length == 2) {
      return parts[1].split('/').last;
    }
    return modelUsed.split('/').last;
  }

  Future<void> _downloadImage(String imageUrl, String prompt) async {
    try {
      // Check current permission status
      var status = await Permission.storage.status;
      
      // For Android 13+ (API 33+), we need different permissions
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ doesn't need storage permission for downloads
          status = PermissionStatus.granted;
        }
      }
      
      // If permission is denied, request it with explanation
      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return;
        
        // Show explanation dialog first
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Iconsax.folder_open, size: 24),
                SizedBox(width: 12),
                Text('Storage Permission'),
              ],
            ),
            content: const Text(
              'This app needs storage permission to save images to your device. '
              'The images will be saved to your Downloads folder.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Allow'),
              ),
            ],
          ),
        );
        
        if (shouldRequest != true || !mounted) return;
        
        // Request permission
        if (status.isPermanentlyDenied) {
          // If permanently denied, open app settings
          final opened = await openAppSettings();
          if (!opened && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable storage permission in app settings'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        } else {
          // Request permission
          status = await Permission.storage.request();
          
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to download images'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        }
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Downloading image...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Handle base64 images
      if (imageUrl.startsWith('data:image')) {
        final base64Data = imageUrl.split(',')[1];
        final bytes = base64Decode(base64Data);
        await _saveImageToGallery(bytes, prompt);
        return;
      }

      // Download from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await _saveImageToGallery(response.bodyBytes, prompt);
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveImageToGallery(List<int> bytes, String prompt) async {
    try {
      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try to use the public Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Could not access storage');

      // Create filename with sanitized prompt
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String sanitizedPrompt = prompt
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      
      // Ensure we don't exceed the string length
      if (sanitizedPrompt.length > 30) {
        sanitizedPrompt = sanitizedPrompt.substring(0, 30);
      }
      
      // Fallback if sanitization removed everything
      if (sanitizedPrompt.isEmpty) {
        sanitizedPrompt = 'image';
      }
      
      final filename = 'ai_image_${sanitizedPrompt}_$timestamp.png';
      final file = File('${directory.path}/$filename');

      // Write file
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Image saved successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Saved to: ${directory.path}',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.close_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage(String id) async {
    try {
      await SupabaseConfig.client
          .from('ai_generated_images')
          .delete()
          .eq('id', id);

      setState(() {
        _images.removeWhere((img) => img.id == id);
        _applyFilters();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showImageDetail(GeneratedImage image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Iconsax.gallery, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Generated Image',
                      style: TextStyle(
                        fontSize: 18,
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
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SmartImageWidget(
                          imageUrl: image.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Prompt
                      Text(
                        'Prompt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          image.prompt,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Model Info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Provider',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    image.modelUsed?.split(':').first ?? 'Unknown',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Model',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _parseModelName(image.modelUsed),
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, y \'at\' h:mm a').format(image.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _downloadImage(image.imageUrl, image.prompt);
                              },
                              icon: const Icon(Iconsax.document_download, size: 18),
                              label: const Text('Download'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Image?'),
                                  content: const Text('This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                        _deleteImage(image.id);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.trash, size: 18),
                            label: const Text(''),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueModels = _getUniqueModels();
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.gallery, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Image Gallery', style: TextStyle(fontSize: 16)),
                  Text(
                    '${_filteredImages.length} images',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by prompt...',
                    prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filters Row
                Row(
                  children: [
                    // Model Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedModel,
                            isExpanded: true,
                            icon: const Icon(Iconsax.arrow_down_1, size: 16),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Row(
                                  children: [
                                    Icon(Iconsax.filter, size: 16),
                                    SizedBox(width: 8),
                                    Text('All Models', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              ...uniqueModels.map((model) => DropdownMenuItem(
                                value: model,
                                child: Text(
                                  _parseModelName(model),
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedModel = value ?? 'all';
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Sort
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(Iconsax.sort, size: 16),
                          items: const [
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text('Newest', style: TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Oldest', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value ?? 'newest';
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Gallery
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Iconsax.gallery,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty || _selectedModel != 'all'
                                  ? 'No matching images'
                                  : 'No images yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedModel != 'all'
                                  ? 'Try adjusting your search or filters'
                                  : 'Generate images using the AI Assistant',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isEmpty && _selectedModel == 'all') ...[
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Iconsax.message_programming),
                                label: const Text('Go to AI Assistant'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadImages,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredImages.length,
                          itemBuilder: (context, index) {
                            final image = _filteredImages[index];
                            return _ImageCard(
                              image: image,
                              onTap: () => _showImageDetail(image),
                              onDelete: () => _deleteImage(image.id),
                              modelName: _parseModelName(image.modelUsed),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final GeneratedImage image;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String modelName;

  const _ImageCard({
    required this.image,
    required this.onTap,
    required this.onDelete,
    required this.modelName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartImageWidget(
                      imageUrl: image.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    // Hover overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.prompt,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMM d, y').format(image.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          modelName.length > 12 ? '${modelName.substring(0, 12)}...' : modelName,
                          style: const TextStyle(fontSize: 10),
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
    );
  }
}

class GeneratedImage {
  final String id;
  final String prompt;
  final String imageUrl;
  final String? modelUsed;
  final DateTime createdAt;

  GeneratedImage({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    this.modelUsed,
    required this.createdAt,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      imageUrl: json['image_url'] as String,
      modelUsed: json['model_used'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
