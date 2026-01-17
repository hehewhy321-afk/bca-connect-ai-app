import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class WidgetService {
  static const platform = MethodChannel('com.mmamc.bca.bca_app/widget');
  
  static Future<String?> getInitialRoute() async {
    try {
      final String? route = await platform.invokeMethod('getInitialRoute');
      return route;
    } catch (e) {
      debugPrint('Error getting initial route: $e');
      return null;
    }
  }
  
  static Future<void> handleWidgetRoute(GoRouter router) async {
    final route = await getInitialRoute();
    if (route != null && route.isNotEmpty) {
      // Delay to ensure app is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      router.go(route);
    }
  }
}
