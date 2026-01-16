import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Request all necessary permissions on app start
  Future<void> requestInitialPermissions(BuildContext context) async {
    if (!context.mounted) return;
    
    // Request notification permission
    await requestNotificationPermission(context);
    
    if (!context.mounted) return;
    
    // Request storage permission
    await requestStoragePermission(context);
  }

  // Request notification permission
  Future<bool> requestNotificationPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      debugPrint('Notification permission already granted');
      return true;
    }

    if (status.isDenied && context.mounted) {
      // Show explanation dialog
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Enable Notifications',
        message: 'BCA Connect needs notification permission to send you important updates about events, forum replies, and announcements.',
        icon: Icons.notifications_active,
      );

      if (shouldRequest == true) {
        final result = await Permission.notification.request();
        
        if (result.isGranted) {
          debugPrint('Notification permission granted');
          return true;
        } else if (result.isPermanentlyDenied && context.mounted) {
          await _showSettingsDialog(context, 'Notifications');
        }
      }
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context, 'Notifications');
    }

    return false;
  }

  // Request storage permission
  Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // For Android 13+ (API 33+), use new photo/media permissions
    Permission storagePermission;
    if (Platform.isAndroid) {
      // Check Android version
      storagePermission = Permission.photos;
    } else {
      storagePermission = Permission.storage;
    }

    final status = await storagePermission.status;
    
    if (status.isGranted) {
      debugPrint('Storage permission already granted');
      return true;
    }

    if (status.isDenied && context.mounted) {
      // Show explanation dialog
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Enable Storage Access',
        message: 'BCA Connect needs storage permission to save and access photos, documents, and other files for events and resources.',
        icon: Icons.folder_open,
      );

      if (shouldRequest == true) {
        final result = await storagePermission.request();
        
        if (result.isGranted) {
          debugPrint('Storage permission granted');
          return true;
        } else if (result.isPermanentlyDenied && context.mounted) {
          await _showSettingsDialog(context, 'Storage');
        }
      }
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context, 'Storage');
    }

    return false;
  }

  // Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  // Show permission explanation dialog
  Future<bool?> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDA7809).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFDA7809), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDA7809),
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  // Show settings dialog when permission is permanently denied
  Future<void> _showSettingsDialog(BuildContext context, String permissionName) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Please enable $permissionName permission in app settings to use this feature.',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDA7809),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
