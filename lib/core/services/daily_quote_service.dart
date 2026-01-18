import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/daily_quote.dart';

class DailyQuoteService {
  static const String _lastShownDateKey = 'daily_quote_last_shown_date';
  static const String _dismissedTodayKey = 'daily_quote_dismissed_today';
  static const String _currentIndexKey = 'daily_quote_current_index';
  
  static List<DailyQuote>? _cachedQuotes;

  /// Load all quotes from JSON file
  static Future<List<DailyQuote>> loadQuotes() async {
    if (_cachedQuotes != null) {
      return _cachedQuotes!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/daily_quotes.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> quotesJson = jsonData['quotes'];
      
      _cachedQuotes = quotesJson.map((json) => DailyQuote.fromJson(json)).toList();
      debugPrint('Loaded ${_cachedQuotes!.length} daily quotes');
      return _cachedQuotes!;
    } catch (e) {
      debugPrint('Error loading daily quotes: $e');
      return [];
    }
  }

  /// Get today's quote
  static Future<DailyQuote?> getTodayQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final quotes = await loadQuotes();
    
    if (quotes.isEmpty) return null;

    // Check if we need to reset (new day)
    final today = DateTime.now();
    final lastShownDate = prefs.getString(_lastShownDateKey);
    final todayString = '${today.year}-${today.month}-${today.day}';

    if (lastShownDate != todayString) {
      // New day - reset dismissed status and move to next quote
      await prefs.setBool(_dismissedTodayKey, false);
      await prefs.setString(_lastShownDateKey, todayString);
      
      // Increment index for new quote
      int currentIndex = prefs.getInt(_currentIndexKey) ?? 0;
      currentIndex = (currentIndex + 1) % quotes.length;
      await prefs.setInt(_currentIndexKey, currentIndex);
      
      debugPrint('New day! Showing quote #$currentIndex');
    }

    // Check if dismissed today
    final isDismissed = prefs.getBool(_dismissedTodayKey) ?? false;
    if (isDismissed) {
      debugPrint('Quote dismissed for today');
      return null;
    }

    // Get current quote
    final currentIndex = prefs.getInt(_currentIndexKey) ?? 0;
    return quotes[currentIndex % quotes.length];
  }

  /// Dismiss today's quote
  static Future<void> dismissToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedTodayKey, true);
    debugPrint('Quote dismissed for today');
  }

  /// Get next quote (for swipe feature)
  static Future<DailyQuote?> getNextQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final quotes = await loadQuotes();
    
    if (quotes.isEmpty) return null;

    int currentIndex = prefs.getInt(_currentIndexKey) ?? 0;
    currentIndex = (currentIndex + 1) % quotes.length;
    await prefs.setInt(_currentIndexKey, currentIndex);
    
    debugPrint('Moved to next quote #$currentIndex');
    return quotes[currentIndex];
  }

  /// Get previous quote (for swipe feature)
  static Future<DailyQuote?> getPreviousQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final quotes = await loadQuotes();
    
    if (quotes.isEmpty) return null;

    int currentIndex = prefs.getInt(_currentIndexKey) ?? 0;
    currentIndex = (currentIndex - 1 + quotes.length) % quotes.length;
    await prefs.setInt(_currentIndexKey, currentIndex);
    
    debugPrint('Moved to previous quote #$currentIndex');
    return quotes[currentIndex];
  }

  /// Check if quote should be shown
  static Future<bool> shouldShowQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool(_dismissedTodayKey) ?? false;
    return !isDismissed;
  }
}
