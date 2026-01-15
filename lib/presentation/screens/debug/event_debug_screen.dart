import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/config/supabase_config.dart';

class EventDebugScreen extends ConsumerStatefulWidget {
  const EventDebugScreen({super.key});

  @override
  ConsumerState<EventDebugScreen> createState() => _EventDebugScreenState();
}

class _EventDebugScreenState extends ConsumerState<EventDebugScreen> {
  String _output = 'Tap "Test Connection" to start...';
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _output = 'Testing connection...\n\n';
    });

    try {
      // Test 1: Check auth
      final user = SupabaseConfig.client.auth.currentUser;
      _addOutput('✅ Auth: ${user?.email ?? "Not logged in"}');

      // Test 2: Fetch all events without filters
      _addOutput('\n📋 Fetching all events...');
      final allEvents = await SupabaseConfig.client
          .from('events')
          .select()
          .order('created_at', ascending: false);
      
      _addOutput('✅ Found ${allEvents.length} total events');
      
      if (allEvents.isNotEmpty) {
        _addOutput('\n📝 First event:');
        final first = allEvents[0];
        _addOutput('  - ID: ${first['id']}');
        _addOutput('  - Title: ${first['title']}');
        _addOutput('  - Status: ${first['status']}');
        _addOutput('  - Start: ${first['start_date']}');
        _addOutput('  - Category: ${first['category']}');
      }

      // Test 3: Fetch upcoming events
      _addOutput('\n📅 Fetching upcoming events...');
      final now = DateTime.now().toIso8601String();
      final upcomingEvents = await SupabaseConfig.client
          .from('events')
          .select()
          .gte('start_date', now)
          .order('start_date', ascending: true);
      
      _addOutput('✅ Found ${upcomingEvents.length} upcoming events');

      // Test 4: Fetch past events
      _addOutput('\n⏰ Fetching past events...');
      final pastEvents = await SupabaseConfig.client
          .from('events')
          .select()
          .lt('start_date', now)
          .order('start_date', ascending: false)
          .limit(5);
      
      _addOutput('✅ Found ${pastEvents.length} past events');

      // Test 5: Check table structure
      _addOutput('\n🔍 Checking table columns...');
      if (allEvents.isNotEmpty) {
        final columns = allEvents[0].keys.toList();
        _addOutput('Columns: ${columns.join(", ")}');
      }

      _addOutput('\n\n✅ All tests completed!');
    } catch (e, stack) {
      _addOutput('\n\n❌ Error: $e');
      _addOutput('\nStack: ${stack.toString().substring(0, 200)}...');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _addOutput(String text) {
    setState(() {
      _output += '$text\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Debug'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _testConnection,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.refresh),
                    label: Text(_loading ? 'Testing...' : 'Test Connection'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    setState(() => _output = 'Output cleared.\n\n');
                  },
                  icon: const Icon(Iconsax.trash),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
