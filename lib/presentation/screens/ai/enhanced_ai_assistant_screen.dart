import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';

enum AIMode { chat, image }

class EnhancedAIAssistantScreen extends ConsumerStatefulWidget {
  const EnhancedAIAssistantScreen({super.key});

  @override
  ConsumerState<EnhancedAIAssistantScreen> createState() => _EnhancedAIAssistantScreenState();
}

class _EnhancedAIAssistantScreenState extends ConsumerState<EnhancedAIAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  AIMode _mode = AIMode.chat;
  StreamingStatus? _streamingStatus;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _messageController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      type: _mode == AIMode.image ? MessageType.image : MessageType.text,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _streamingStatus = StreamingStatus(
        isStreaming: true,
        provider: '',
        model: '',
        tokensReceived: 0,
        startTime: DateTime.now(),
      );
    });

    final messageText = _messageController.text.trim();
    _messageController.clear();
    _scrollToBottom();

    // Use messageText in the API call
    debugPrint('Sending message: $messageText');

    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session == null) {
        throw Exception('Please log in to use the AI assistant');
      }

      final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', 
        defaultValue: 'https://xtpkzqeylypdsxspmbmg.supabase.co');
      final url = '$supabaseUrl/functions/v1/ai-chat';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'messages': _messages.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }).toList(),
          'mode': _mode == AIMode.image ? 'image' : 'chat',
        }),
      );

      if (!mounted) return;

      final provider = response.headers['x-ai-provider'] ?? 'unknown';
      final model = response.headers['x-ai-model'] ?? 'unknown';

      setState(() {
        _streamingStatus = _streamingStatus?.copyWith(
          provider: provider,
          model: model,
        );
      });

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get response');
      }

      // Check if it's an image response
      final contentType = response.headers['content-type'];
      if (contentType?.contains('application/json') == true) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['type'] == 'image') {
          String? imageUrl;
          
          if (jsonData['output'] is String) {
            imageUrl = jsonData['output'];
          } else if (jsonData['output']?['url'] != null) {
            imageUrl = jsonData['output']['url'];
          } else if (jsonData['output']?['image_url'] != null) {
            imageUrl = jsonData['output']['image_url'];
          }
          
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
                text: 'Generated image for: "${jsonData['prompt']}"',
                isUser: false,
                timestamp: DateTime.now(),
                type: MessageType.image,
                imageUrl: imageUrl,
                provider: jsonData['provider'],
                model: jsonData['model'],
              ));
              _isLoading = false;
              _streamingStatus = null;
            });
            _scrollToBottom();
          }
          return;
        }
      }

      // Handle streaming text response
      if (_mode == AIMode.chat) {
        await _handleStreamingResponse(response, provider, model);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: 'I apologize, but I\'m having trouble connecting right now. Error: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ));
          _isLoading = false;
          _streamingStatus = null;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleStreamingResponse(http.Response response, String provider, String model) async {
    final assistantId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    
    setState(() {
      _messages.add(ChatMessage(
        id: assistantId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
        provider: provider,
        model: model,
      ));
    });

    // For now, just use the full response (streaming would require SSE support)
    final responseText = response.body;
    
    // Simulate streaming by adding text gradually
    for (int i = 0; i < responseText.length; i += 5) {
      if (!mounted) break;
      
      final chunk = responseText.substring(0, i + 5 > responseText.length ? responseText.length : i + 5);
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(text: chunk);
        }
      });
      
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _streamingStatus = null;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() => _messages.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestedQuestions = _mode == AIMode.image
        ? [
            'Generate an image of a futuristic classroom',
            'Create an image of a beautiful sunset over mountains',
            'Draw a cute robot studying computer science',
            'Make an image of Nepal\'s Himalayan landscape',
          ]
        : [
            'Explain polymorphism in Java',
            'What is normalization in databases?',
            'Write a Python function for binary search',
            'How does recursion work?',
          ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ModernTheme.orangeGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.message_programming, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Study Assistant', style: TextStyle(fontSize: 16)),
                  Text(
                    'Chat, Voice & Image Generation',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash),
              onPressed: _clearChat,
              tooltip: 'Clear Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Streaming Status
          if (_streamingStatus?.isStreaming == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Iconsax.flash_1, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_streamingStatus?.provider} • ${_streamingStatus?.model}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          
          // Messages Area
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(suggestedQuestions)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading && _messages.last.isUser ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Mode Toggle
                    IconButton(
                      icon: Icon(
                        _mode == AIMode.image ? Iconsax.gallery : Iconsax.message_text,
                        color: _mode == AIMode.image
                            ? ModernTheme.primaryOrange
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _mode = _mode == AIMode.chat ? AIMode.image : AIMode.chat;
                        });
                      },
                      tooltip: _mode == AIMode.chat ? 'Switch to Image Mode' : 'Switch to Chat Mode',
                    ),
                    
                    // Input Field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _mode == AIMode.image
                              ? 'Describe the image you want...'
                              : 'Ask anything about your studies...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoading,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Send Button
                    Container(
                      decoration: const BoxDecoration(
                        gradient: ModernTheme.orangeGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Iconsax.send_1, color: Colors.white),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == AIMode.image
                      ? '🎨 IMAGE MODE ON • Describe any image to generate'
                      : '💬 Chat Mode • Ask anything about BCA studies',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<String> suggestions) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: _mode == AIMode.image
                    ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                    : ModernTheme.orangeGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _mode == AIMode.image ? Iconsax.gallery : Iconsax.message_programming,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _mode == AIMode.image ? 'Image Generation Mode' : 'How can I help you today?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _mode == AIMode.image
                  ? 'Describe any image you want to create and I\'ll generate it for you!'
                  : 'Ask me anything about your BCA curriculum, programming concepts, or toggle Image Mode!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((question) {
                return _SuggestionChip(
                  label: question,
                  icon: _mode == AIMode.image ? Iconsax.gallery : Iconsax.message_programming,
                  onTap: () {
                    _messageController.text = question;
                    _sendMessage();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

enum MessageType { text, image }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  final String? provider;
  final String? model;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.imageUrl,
    this.provider,
    this.model,
  });

  ChatMessage copyWith({
    String? text,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      type: type,
      imageUrl: imageUrl ?? this.imageUrl,
      provider: provider,
      model: model,
    );
  }
}

class StreamingStatus {
  final bool isStreaming;
  final String provider;
  final String model;
  final int tokensReceived;
  final DateTime startTime;

  StreamingStatus({
    required this.isStreaming,
    required this.provider,
    required this.model,
    required this.tokensReceived,
    required this.startTime,
  });

  StreamingStatus copyWith({
    bool? isStreaming,
    String? provider,
    String? model,
    int? tokensReceived,
  }) {
    return StreamingStatus(
      isStreaming: isStreaming ?? this.isStreaming,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      tokensReceived: tokensReceived ?? this.tokensReceived,
      startTime: startTime,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: message.type == MessageType.image
                    ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                    : ModernTheme.orangeGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                message.type == MessageType.image ? Iconsax.gallery : Iconsax.message_programming,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? ModernTheme.primaryOrange
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: message.type == MessageType.image && message.imageUrl != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser ? Colors.white : null,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  padding: const EdgeInsets.all(16),
                                  color: Colors.grey[200],
                                  child: const Text('Failed to load image'),
                                ),
                              ),
                            ),
                          ],
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: message.isUser ? Colors.white : null,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            code: TextStyle(
                              backgroundColor: message.isUser
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.05),
                              color: message.isUser ? Colors.white : null,
                            ),
                          ),
                        ),
                ),
                if (!message.isUser && message.provider != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'via ${message.provider}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.user,
                size: 16,
                color: ModernTheme.primaryOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: ModernTheme.orangeGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.message_programming,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: ModernTheme.primaryOrange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ModernTheme.primaryOrange),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
