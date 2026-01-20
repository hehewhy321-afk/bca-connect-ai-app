import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUpdateService {
  static const String githubRepo = 'hehewhy321-afk/bca-connect-ai-app';
  static const String githubApiUrl = 'https://api.github.com/repos/$githubRepo/releases/latest';
  
  // Set to false if you haven't set up GitHub releases yet
  static const bool isUpdateCheckEnabled = true;

  /// Check for updates from GitHub releases
  static Future<UpdateInfo?> checkForUpdates() async {
    // If update check is disabled, return null
    if (!isUpdateCheckEnabled) {
      throw Exception('UPDATE_DISABLED');
    }
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest release from GitHub
      final dio = Dio();
      final response = await dio.get(
        githubApiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        final releaseNotes = data['body'] as String? ?? 'No release notes available';
        final publishedAt = DateTime.parse(data['published_at']);

        // Find APK assets
        final assets = data['assets'] as List;
        String? apkUrl64;
        String? apkUrl32;
        int? apkSize64;
        int? apkSize32;

        for (var asset in assets) {
          final name = asset['name'] as String;
          if (name.contains('64bit') && name.endsWith('.apk')) {
            apkUrl64 = asset['browser_download_url'];
            apkSize64 = asset['size'];
          } else if (name.contains('32bit') && name.endsWith('.apk')) {
            apkUrl32 = asset['browser_download_url'];
            apkSize32 = asset['size'];
          }
        }

        // Compare versions
        final isUpdateAvailable = _compareVersions(latestVersion, currentVersion) > 0;

        if (isUpdateAvailable) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            publishedAt: publishedAt,
            apkUrl64: apkUrl64,
            apkUrl32: apkUrl32,
            apkSize64: apkSize64,
            apkSize32: apkSize32,
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('NO_RELEASES');
      } else {
        throw Exception('SERVER_ERROR');
      }
      return null;
    } on SocketException {
      throw Exception('NO_INTERNET');
    } on TimeoutException {
      throw Exception('TIMEOUT');
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      rethrow;
    }
  }

  /// Compare two version strings (e.g., "1.3.0" vs "1.2.5")
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Download and install APK
  static Future<void> downloadAndInstall(BuildContext context, String apkUrl) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to download updates'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show downloading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading update...'),
              ],
            ),
          ),
        );
      }

      // Download APK
      final dio = Dio();
      final response = await dio.get(
        apkUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode == 200) {
        // Save to Downloads folder
        final directory = Directory('/storage/emulated/0/Download');
        final fileName = 'BCA-Association-Update-${DateTime.now().millisecondsSinceEpoch}.apk';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.data as List<int>);

        if (context.mounted) {
          Navigator.pop(context); // Close downloading dialog

          // Show success dialog with install option
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Download Complete'),
                ],
              ),
              content: Text('APK saved to:\n${file.path}\n\nTap "Install" to proceed.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Open APK file for installation
                    final uri = Uri.parse('file://${file.path}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text('Install'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to download APK');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close downloading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format file size
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final DateTime publishedAt;
  final String? apkUrl64;
  final String? apkUrl32;
  final int? apkSize64;
  final int? apkSize32;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.publishedAt,
    this.apkUrl64,
    this.apkUrl32,
    this.apkSize64,
    this.apkSize32,
  });
}
