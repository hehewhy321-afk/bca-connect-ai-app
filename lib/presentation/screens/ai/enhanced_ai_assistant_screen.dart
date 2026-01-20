import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/cached_image.dart';
import 'image_gallery_screen.dart';
import '../../../core/constants/easter_eggs.dart';
import '../../widgets/easter_egg_widget.dart';

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
  bool _isCancelled = false; // Flag to track cancellation
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
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button color
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _speechAvailable = await _speech.initialize(
          onError: (error) {
            debugPrint('Speech error: $error');
            if (mounted) {
              setState(() {
                _speechAvailable = false;
                _isListening = false;
              });
            }
          },
          onStatus: (status) {
            debugPrint('Speech status: $status');
            if (status == 'notListening' && mounted) {
              setState(() => _isListening = false);
            }
          },
        );
        if (mounted) setState(() {});
      } else {
        debugPrint('Microphone permission denied');
        _speechAvailable = false;
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
      _speechAvailable = false;
      if (mounted) setState(() {});
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

  void _cancelGeneration() {
    setState(() {
      _isCancelled = true;
      _isLoading = false;
      _streamingStatus = null;
    });
    
    // Remove the last assistant message if it's incomplete
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      setState(() {
        _messages.removeLast();
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generation cancelled'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network/Connection errors
    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('network is unreachable')) {
      return '🌐 No internet connection. Please check your network and try again.';
    }
    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return '⏱️ Request timed out. The server is taking too long to respond. Please try again.';
    }
    
    if (errorString.contains('connection refused') || errorString.contains('connection reset')) {
      return '🔌 Unable to connect to the server. Please check your internet connection.';
    }
    
    // Authentication errors
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return '🔐 Session expired. Please log out and log in again.';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return '🚫 Access denied. You don\'t have permission to use this feature.';
    }
    
    // Rate limiting
    if (errorString.contains('rate limit') || errorString.contains('too many requests') || errorString.contains('429')) {
      return '⏳ Too many requests. Please wait a moment and try again.';
    }
    
    // Server errors
    if (errorString.contains('500') || errorString.contains('internal server error')) {
      return '⚠️ Server error. Our team has been notified. Please try again later.';
    }
    
    if (errorString.contains('503') || errorString.contains('service unavailable')) {
      return '🔧 Service temporarily unavailable. Please try again in a few minutes.';
    }
    
    // API/Credits errors
    if (errorString.contains('credits exhausted') || errorString.contains('quota exceeded')) {
      return '💳 AI credits exhausted. Please contact the administrator.';
    }
    
    if (errorString.contains('invalid api key') || errorString.contains('api key')) {
      return '🔑 AI service configuration error. Please contact support.';
    }
    
    // Generic fallback
    if (errorString.contains('exception') || errorString.contains('error')) {
      return '❌ Something went wrong. Please check your internet connection and try again.';
    }
    
    return '❌ Unable to process your request. Please try again.';
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
      _isCancelled = false; // Reset cancel flag
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
      
      final dio = Dio();
      final response = await dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
          validateStatus: (status) => true, // Accept all status codes
        ),
        data: {
          'messages': _messages.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }).toList(),
          'mode': _mode == AIMode.image ? 'image' : 'chat',
        },
      );

      if (!mounted) return;

      final provider = response.headers.value('x-ai-provider') ?? 'unknown';
      final model = response.headers.value('x-ai-model') ?? 'unknown';

      setState(() {
        _streamingStatus = _streamingStatus?.copyWith(
          provider: provider,
          model: model,
        );
      });

      if (response.statusCode != 200) {
        final errorData = response.data;
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
      final contentType = response.headers.value('content-type');
      if (contentType?.contains('application/json') == true) {
        final jsonData = response.data is String ? jsonDecode(response.data) : response.data;
        
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
        final friendlyError = _getUserFriendlyError(e);
        setState(() {
          _messages.add(ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: friendlyError,
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

  Future<void> _handleStreamingResponse(Response response, String provider, String model) async {
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
      final lines = (response.data as String).split('\n');
      String fullText = '';
      
      for (final line in lines) {
        if (!mounted || _isCancelled) break; // Check for cancellation
        
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          
          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            
            if (content != null) {
              fullText += content;
              
              if (_isCancelled) break; // Check again before updating
              
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
      if (!_isCancelled) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == assistantId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(text: response.data.toString());
          }
        });
      }
    }

    if (mounted && !_isCancelled) {
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

    // Show modern dialog with options
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.document_download, color: ModernTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Export Chat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to export your conversation:'),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    ModernTheme.primaryOrange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.save_2, color: ModernTheme.primaryOrange, size: 28),
                title: const Text('Save to Device', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Save in Downloads folder'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(context, 'save'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.share, color: Colors.blue, size: 28),
                title: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Share via other apps'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (action == null) return;

    try {
      // Create HTML content
      final html = _generateChatHTML();
      final fileName = 'ai-chat-${DateFormat('yyyy-MM-dd-HHmmss').format(DateTime.now())}.html';
      
      if (action == 'save') {
        // Save to Downloads folder
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final file = File('${appDir.path}/$fileName');
          await file.writeAsString(html);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to: ${file.path}'),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(html);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Chat saved to Downloads folder!'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } else {
        // Share via other apps
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(html);
        
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'AI Chat Conversation - ${DateFormat('MMM d, y').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export chat: $e'),
            backgroundColor: Colors.red,
          ),
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
    // Updated suggestions: 2 chat + 2 image examples
    final suggestedQuestions = [
      // Chat examples
      'Explain polymorphism in Java',
      'What is normalization in databases?',
      // Image examples
      'Generate a futuristic classroom with AI',
      'Create a beautiful mountain landscape',
    ];

    return Scaffold(
      appBar: AppBar(
        title: EasterEggWidget(
          soundFile: EasterEggs.aiAssistant.soundFile,
          emoji: EasterEggs.aiAssistant.emoji,
          message: EasterEggs.aiAssistant.message,
          child: Row(
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
          // Streaming Status with Stop Button
          if (_streamingStatus?.isStreaming == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ModernTheme.primaryOrange.withValues(alpha: 0.15),
                    ModernTheme.primaryOrange.withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.flash_1,
                      size: 14,
                      color: ModernTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generating response...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.primaryOrange,
                          ),
                        ),
                        Text(
                          '${_streamingStatus?.provider} • ${_streamingStatus?.model}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stop Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _cancelGeneration,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.stop_circle,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                    // Mode Toggle Button (+ icon on left, gallery icon when active)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _mode == AIMode.image
                            ? const Color(0xFF8B5CF6) // Purple for image mode
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _mode == AIMode.image ? Iconsax.gallery5 : Iconsax.add,
                          color: _mode == AIMode.image
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                        onPressed: _isLoading ? null : () {
                          setState(() {
                            _mode = _mode == AIMode.chat ? AIMode.image : AIMode.chat;
                          });
                        },
                        tooltip: _mode == AIMode.chat ? 'Switch to Image Mode' : 'Switch to Chat Mode',
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Input Field with Voice Icon Inside
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
                                      : 'Message AI Assistant...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.only(
                                left: 20,
                                right: 50, // Space for voice icon
                                top: 12,
                                bottom: 12,
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
                          // Voice Input Button Inside TextField
                          Positioned(
                            right: 8,
                            top: 4,
                            bottom: 4,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.red.shade100
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _isListening ? Iconsax.microphone_slash_1 : Iconsax.microphone,
                                  color: _isListening
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: _isLoading ? null : _toggleListening,
                                tooltip: _speechAvailable
                                    ? (_isListening ? 'Stop Listening' : 'Voice Input')
                                    : 'Voice input not available',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Send Button (arrow up, changes color based on text)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isNotEmpty
                            ? ModernTheme.primaryOrange
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Iconsax.arrow_up_1,
                          color: _messageController.text.trim().isNotEmpty
                              ? Colors.white
                              : Colors.grey,
                          size: 20,
                        ),
                        onPressed: _isLoading || _messageController.text.trim().isEmpty
                            ? null
                            : _sendMessage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isListening
                      ? '🎤 LISTENING... Speak now!'
                      : _mode == AIMode.image
                          ? '🎨 IMAGE MODE • Tip: Be specific! e.g., "A sunset over mountains with purple sky"'
                          : '💬 Chat Mode • Ask anything about BCA studies',
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
            // Show all 4 suggestions (2 chat + 2 image)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // Chat examples
                _SuggestionChip(
                  label: suggestions[0],
                  icon: Iconsax.message_programming,
                  onTap: () {
                    setState(() => _mode = AIMode.chat);
                    _messageController.text = suggestions[0];
                    _sendMessage();
                  },
                ),
                _SuggestionChip(
                  label: suggestions[1],
                  icon: Iconsax.message_programming,
                  onTap: () {
                    setState(() => _mode = AIMode.chat);
                    _messageController.text = suggestions[1];
                    _sendMessage();
                  },
                ),
                // Image examples
                _SuggestionChip(
                  label: suggestions[2],
                  icon: Iconsax.gallery,
                  onTap: () {
                    setState(() => _mode = AIMode.image);
                    _messageController.text = suggestions[2];
                    _sendMessage();
                  },
                ),
                _SuggestionChip(
                  label: suggestions[3],
                  icon: Iconsax.gallery,
                  onTap: () {
                    setState(() => _mode = AIMode.image);
                    _messageController.text = suggestions[3];
                    _sendMessage();
                  },
                ),
              ],
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

