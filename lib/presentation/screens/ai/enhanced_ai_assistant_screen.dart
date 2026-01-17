import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/cached_image.dart';
import 'image_gallery_screen.dart';

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
  
  // Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _interimTranscript = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _speechAvailable = await _speech.initialize(
          onError: (error) => debugPrint('Speech error: $error'),
          onStatus: (status) => debugPrint('Speech status: $status'),
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _saveImageToDatabase({
    required String prompt,
    required String imageUrl,
    String? provider,
    String? model,
  }) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final modelUsed = provider != null && model != null ? '$provider:$model' : null;

      // Save generated image to database (like web version)
      await SupabaseConfig.client.from('ai_generated_images').insert({
        'user_id': user.id,
        'prompt': prompt,
        'image_url': imageUrl,
        'model_used': modelUsed,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Image saved to database successfully');
    } catch (e) {
      debugPrint('Error saving image to database: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _interimTranscript = '';
      });
    } else {
      setState(() => _isListening = true);
      
      await _speech.listen(
        onResult: (result) {
          setState(() {
            if (result.finalResult) {
              // Add final result to input
              final newText = _messageController.text.isEmpty
                  ? result.recognizedWords
                  : '${_messageController.text} ${result.recognizedWords}';
              _messageController.text = newText;
              _interimTranscript = '';
            } else {
              // Show interim results
              _interimTranscript = result.recognizedWords;
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.cancel();
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
        final errorCode = errorData['code'];
        
        String errorMessage = errorData['error'] ?? 'Failed to get response';
        
        if (errorCode == 'RATE_LIMITED') {
          errorMessage = 'Rate Limited: Too many requests. Please wait a moment and try again.';
        } else if (errorCode == 'CREDITS_EXHAUSTED') {
          errorMessage = 'Credits Exhausted: AI credits exhausted. Please contact admin.';
        } else if (errorCode == 'INVALID_API_KEY') {
          errorMessage = 'Invalid API Key: Please check AI settings.';
        }
        
        throw Exception(errorMessage);
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
            // Save image to database
            if (imageUrl != null) {
              _saveImageToDatabase(
                prompt: jsonData['prompt'] ?? userMessage.text,
                imageUrl: imageUrl,
                provider: jsonData['provider'],
                model: jsonData['model'],
              );
            }
            
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

    try {
      // Parse SSE stream
      final lines = response.body.split('\n');
      String fullText = '';
      
      for (final line in lines) {
        if (!mounted) break;
        
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          
          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            
            if (content != null) {
              fullText += content;
              
              setState(() {
                final index = _messages.indexWhere((m) => m.id == assistantId);
                if (index != -1) {
                  _messages[index] = _messages[index].copyWith(text: fullText);
                  _streamingStatus = _streamingStatus?.copyWith(
                    tokensReceived: (_streamingStatus?.tokensReceived ?? 0) + 1,
                  );
                }
              });
              
              _scrollToBottom();
              await Future.delayed(const Duration(milliseconds: 10));
            }
          } catch (e) {
            debugPrint('Error parsing SSE data: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling streaming response: $e');
      // Fallback: use full response body
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(text: response.body);
        }
      });
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

  Future<void> _downloadChat() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to download')),
      );
      return;
    }

    try {
      // Create HTML content
      final html = _generateChatHTML();
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/ai-chat-${DateTime.now().millisecondsSinceEpoch}.html');
      
      // Write HTML to file
      await file.writeAsString(html);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AI Chat Conversation - ${DateFormat('MMM d, y').format(DateTime.now())}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export chat: $e')),
        );
      }
    }
  }

  String _generateChatHTML() {
    final user = SupabaseConfig.client.auth.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';
    
    final messagesHtml = _messages.map((message) {
      final isUser = message.isUser;
      final avatar = isUser ? '👤' : '🤖';
      final role = isUser ? 'user' : 'assistant';
      
      String contentHtml = message.text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('\n', '<br>');
      
      // Format code blocks
      contentHtml = contentHtml.replaceAllMapped(
        RegExp(r'```(\w+)?\n(.*?)```', multiLine: true, dotAll: true),
        (match) => '<pre class="code-block"><code>${match.group(2)}</code></pre>',
      );
      
      // Format inline code
      contentHtml = contentHtml.replaceAllMapped(
        RegExp(r'`([^`]+)`'),
        (match) => '<code class="inline-code">${match.group(1)}</code>',
      );
      
      // Format bold
      contentHtml = contentHtml.replaceAllMapped(
        RegExp(r'\*\*([^*]+)\*\*'),
        (match) => '<strong>${match.group(1)}</strong>',
      );
      
      String imageHtml = '';
      if (message.type == MessageType.image && message.imageUrl != null) {
        imageHtml = '<img src="${message.imageUrl}" alt="Generated image" class="message-image" />';
      }
      
      String metaHtml = '';
      if (!isUser && message.provider != null) {
        metaHtml = '<div class="message-meta"><span class="badge provider">${message.provider}:${message.model}</span></div>';
      }
      
      return '''
        <div class="message $role">
          <div class="avatar $role">$avatar</div>
          <div class="message-content">
            <div class="message-bubble">
              $contentHtml
              $imageHtml
            </div>
            $metaHtml
          </div>
        </div>
      ''';
    }).join('\n');
    
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AI Chat - ${DateFormat('MMM d, y').format(DateTime.now())}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 40px 20px;
      min-height: 100vh;
      line-height: 1.6;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
      background: white;
      border-radius: 24px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }
    .header {
      background: linear-gradient(135deg, #DA7809 0%, #FF9500 100%);
      color: white;
      padding: 40px;
      text-align: center;
    }
    .header h1 {
      font-size: 32px;
      font-weight: 800;
      margin-bottom: 8px;
    }
    .header p {
      font-size: 14px;
      opacity: 0.9;
    }
    .stats {
      display: flex;
      justify-content: center;
      gap: 40px;
      margin-top: 24px;
      padding-top: 24px;
      border-top: 1px solid rgba(255, 255, 255, 0.2);
    }
    .stat-value {
      font-size: 28px;
      font-weight: 800;
      display: block;
    }
    .stat-label {
      font-size: 12px;
      opacity: 0.8;
      text-transform: uppercase;
    }
    .messages {
      padding: 40px;
    }
    .message {
      display: flex;
      gap: 16px;
      margin-bottom: 32px;
    }
    .message.user {
      flex-direction: row-reverse;
    }
    .avatar {
      width: 40px;
      height: 40px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
      flex-shrink: 0;
    }
    .avatar.user {
      background: linear-gradient(135deg, #DA7809 0%, #FF9500 100%);
    }
    .avatar.assistant {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .message-content {
      flex: 1;
      max-width: 70%;
    }
    .message.user .message-content {
      text-align: right;
    }
    .message-bubble {
      padding: 16px 20px;
      border-radius: 16px;
      display: inline-block;
      max-width: 100%;
      word-wrap: break-word;
      text-align: left;
    }
    .message.user .message-bubble {
      background: linear-gradient(135deg, #DA7809 0%, #FF9500 100%);
      color: white;
      border-bottom-right-radius: 4px;
    }
    .message.assistant .message-bubble {
      background: #f7f7f8;
      color: #1a1a1a;
      border-bottom-left-radius: 4px;
    }
    .inline-code {
      background: rgba(0, 0, 0, 0.08);
      padding: 2px 6px;
      border-radius: 4px;
      font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
      font-size: 0.9em;
    }
    .code-block {
      background: #2d2d2d;
      color: #f8f8f2;
      padding: 16px;
      border-radius: 8px;
      overflow-x: auto;
      margin: 12px 0;
      font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
      font-size: 13px;
    }
    .message-image {
      margin-top: 12px;
      border-radius: 12px;
      max-width: 100%;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }
    .message-meta {
      font-size: 11px;
      margin-top: 8px;
      opacity: 0.6;
    }
    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 10px;
      font-weight: 600;
      background: #f0fdf4;
      color: #15803d;
    }
    .footer {
      background: #f7f7f8;
      padding: 32px 40px;
      text-align: center;
      border-top: 1px solid #e5e5e5;
    }
    .footer .logo {
      font-size: 18px;
      font-weight: 800;
      background: linear-gradient(135deg, #DA7809 0%, #FF9500 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🤖 AI Chat Conversation</h1>
      <p>Exported on ${DateFormat('MMM d, y • h:mm a').format(DateTime.now())}</p>
      <div class="stats">
        <div class="stat">
          <span class="stat-value">${_messages.length}</span>
          <span class="stat-label">Messages</span>
        </div>
        <div class="stat">
          <span class="stat-value">${_messages.where((m) => m.type == MessageType.image).length}</span>
          <span class="stat-label">Images</span>
        </div>
        <div class="stat">
          <span class="stat-value">$userName</span>
          <span class="stat-label">Account</span>
        </div>
      </div>
    </div>
    <div class="messages">
      $messagesHtml
    </div>
    <div class="footer">
      <p class="logo">BCA AI Study Assistant</p>
      <p>Powered by AI • MMAMC College</p>
    </div>
  </div>
</body>
</html>
    ''';
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
          IconButton(
            icon: const Icon(Iconsax.gallery),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImageGalleryScreen(),
                ),
              );
            },
            tooltip: 'Image Gallery',
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.document_download),
              onPressed: _downloadChat,
              tooltip: 'Download Chat',
            ),
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
                    // Voice Button
                    if (_speechAvailable)
                      IconButton(
                        icon: Icon(
                          _isListening ? Iconsax.microphone_slash_1 : Iconsax.microphone,
                          color: _isListening
                              ? Colors.red
                              : ModernTheme.primaryOrange,
                        ),
                        onPressed: _isLoading ? null : _toggleListening,
                        tooltip: _isListening ? 'Stop Listening' : 'Voice Input',
                      ),
                    
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
                      child: Stack(
                        children: [
                          TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'Listening... Speak now!'
                                  : _mode == AIMode.image
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
                          // Interim transcript overlay
                          if (_interimTranscript.isNotEmpty)
                            Positioned(
                              left: 20,
                              top: 12,
                              child: Text(
                                _interimTranscript,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
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
                  _isListening
                      ? '🎤 LISTENING... Speak now!'
                      : _mode == AIMode.image
                          ? '🎨 IMAGE MODE ON • Describe any image to generate'
                          : '💬 Chat Mode • Ask anything about BCA studies${_speechAvailable ? ' • 🎤 Voice available' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isListening
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data
        final base64Data = imageUrl.split(',')[1];
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: 250,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 250,
              height: 250,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Center(
                child: Text('Failed to load image'),
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return Container(
          width: 250,
          height: 250,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: const Center(
            child: Text('Invalid image format'),
          ),
        );
      }
    }
    
    // It's a URL, use CachedImage
    return CachedImage(
      imageUrl: imageUrl,
      width: 250,
      height: 250,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      errorWidget: Container(
        width: 250,
        height: 250,
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: const Center(
          child: Text('Failed to load image'),
        ),
      ),
    );
  }

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
                            // Handle both base64 and URL images
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageWidget(message.imageUrl!),
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
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(50),
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

