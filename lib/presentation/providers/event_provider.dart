import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/models/event.dart';

// Event Repository Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

// All Events Provider
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  try {
    final events = await ref.watch(eventRepositoryProvider).getEvents();
    debugPrint('Events Provider: Loaded ${events.length} events');
    return events;
  } catch (e) {
    debugPrint('Events Provider Error: $e');
    rethrow;
  }
});

// Upcoming Events Provider
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  try {
    final events = await ref.watch(eventRepositoryProvider).getUpcomingEvents();
    debugPrint('Upcoming Events Provider: Loaded ${events.length} events');
    return events;
  } catch (e) {
    debugPrint('Upcoming Events Provider Error: $e');
    rethrow;
  }
});

// Featured Events Provider
final featuredEventsProvider = FutureProvider<List<Event>>((ref) async {
  try {
    final events = await ref.watch(eventRepositoryProvider).getFeaturedEvents();
    debugPrint('Featured Events Provider: Loaded ${events.length} events');
    return events;
  } catch (e) {
    debugPrint('Featured Events Provider Error: $e');
    rethrow;
  }
});

// Event Stream Provider
final eventStreamProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).streamEvents();
});

// Event Detail Provider
final eventDetailProvider = FutureProvider.family<Event?, String>((ref, id) async {
  try {
    final event = await ref.watch(eventRepositoryProvider).getEventById(id);
    debugPrint('Event Detail Provider: Loaded event $id');
    return event;
  } catch (e) {
    debugPrint('Event Detail Provider Error: $e');
    rethrow;
  }
});

// User Registrations Provider
final userRegistrationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final registrations = await ref.watch(eventRepositoryProvider).getUserRegistrations();
    debugPrint('User Registrations Provider: Loaded ${registrations.length} registrations');
    return registrations;
  } catch (e) {
    debugPrint('User Registrations Provider Error: $e');
    rethrow;
  }
});

// Is User Registered Provider
final isUserRegisteredProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  try {
    final isRegistered = await ref.watch(eventRepositoryProvider).isUserRegistered(eventId);
    debugPrint('Is User Registered Provider: Event $eventId - $isRegistered');
    return isRegistered;
  } catch (e) {
    debugPrint('Is User Registered Provider Error: $e');
    rethrow;
  }
});

