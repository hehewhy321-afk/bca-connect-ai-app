import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  String _result = 'Tap buttons to test...';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing connection...';
    });

    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      
      setState(() {
        _result = '''
✅ Supabase Connected!

User: ${user?.email ?? 'Not logged in'}
User ID: ${user?.id ?? 'N/A'}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEvents() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching events...';
    });

    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('events')
          .select()
          .limit(5);

      setState(() {
        _result = '''
✅ Events Fetched!

Count: ${(response as List).length}
Data: ${response.toString()}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error fetching events: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testForumPosts() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching forum posts...';
    });

    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('forum_posts')
          .select()
          .limit(5);

      setState(() {
        _result = '''
✅ Forum Posts Fetched!

Count: ${(response as List).length}
Data: ${response.toString()}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error fetching forum posts: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCertificates() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching certificates...';
    });

    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() {
          _result = '❌ Not logged in';
        });
        return;
      }

      final response = await client
          .from('certificates')
          .select()
          .eq('user_id', userId)
          .limit(5);

      setState(() {
        _result = '''
✅ Certificates Fetched!

Count: ${(response as List).length}
Data: ${response.toString()}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error fetching certificates: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testResources() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching resources...';
    });

    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('resources')
          .select()
          .limit(5);

      setState(() {
        _result = '''
✅ Resources Fetched!

Count: ${(response as List).length}
Data: ${response.toString()}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error fetching resources: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Data Fetching'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Text(
                      _result,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi),
              label: const Text('Test Connection'),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _testEvents,
              icon: const Icon(Icons.event),
              label: const Text('Test Events'),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _testForumPosts,
              icon: const Icon(Icons.forum),
              label: const Text('Test Forum Posts'),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _testCertificates,
              icon: const Icon(Icons.card_membership),
              label: const Text('Test Certificates'),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _testResources,
              icon: const Icon(Icons.folder),
              label: const Text('Test Resources'),
            ),
          ],
        ),
      ),
    );
  }
}
