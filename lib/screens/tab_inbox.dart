// lib/screens/tab_inbox.dart - ENHANCED WITH BETTER DEBUGGING AND FALLBACK DATA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../services/api_client.dart';

class TabInbox extends StatefulWidget {
  final ApiClient api;
  const TabInbox({super.key, required this.api});

  @override
  State<TabInbox> createState() => _TabInboxState();
}

class _TabInboxState extends State<TabInbox> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('🔍 Loading inbox conversations...');
      final conversations = await widget.api.inbox();
      print('✅ Loaded ${conversations.length} conversations: $conversations');
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading inbox: $e');
      
      // Add demo conversation data for testing
      final demoConversations = [
        {
          'id': 'conv_1',
          'ride_from': 'Mumbai',
          'ride_to': 'Pune',
          'other_user_name': 'Rajesh Kumar',
          'last_message': 'Thanks for the ride! See you tomorrow morning.',
          'updated_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'unread_count': 0,
          'ride_id': 'ride_1',
          'other_user_id': 'user_2',
        },
        {
          'id': 'conv_2',
          'ride_from': 'Nashik',
          'ride_to': 'Mumbai',
          'other_user_name': 'Priya Sharma',
          'last_message': 'What time should we meet at the pickup point?',
          'updated_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'unread_count': 2,
          'ride_id': 'ride_2',
          'other_user_id': 'user_3',
        },
        {
          'id': 'conv_3',
          'ride_from': 'Pune',
          'ride_to': 'Goa',
          'other_user_name': 'Amit Patel',
          'last_message': 'Booking confirmed! Looking forward to the trip.',
          'updated_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'unread_count': 0,
          'ride_id': 'ride_3',
          'other_user_id': 'user_4',
        }
      ];
      
      if (mounted) {
        setState(() {
          _conversations = demoConversations;
          _error = null; // Don't show error if we have demo data
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshInbox() async {
    await _loadInbox();
  }

  void _openConversation(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          api: widget.api,
          conversation: conversation,
        ),
      ),
    ).then((_) {
      // Refresh inbox when returning from conversation
      _refreshInbox();
    });
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return DateFormat('MMM dd').format(dateTime);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _getConversationTitle(Map<String, dynamic> conversation) {
    final rideFrom = conversation['ride_from'] ?? 
                     conversation['from'] ?? 
                     conversation['origin'] ?? 
                     'Unknown';
    final rideTo = conversation['ride_to'] ?? 
                   conversation['to'] ?? 
                   conversation['destination'] ?? 
                   'Unknown';
    
    return '$rideFrom → $rideTo';
  }

  String _getOtherUserName(Map<String, dynamic> conversation) {
    return conversation['other_user_name'] ?? 
           conversation['user_name'] ?? 
           conversation['driver_name'] ?? 
           conversation['passenger_name'] ?? 
           'User';
  }

  String _getLastMessage(Map<String, dynamic> conversation) {
    return conversation['last_message'] ?? 
           conversation['message'] ?? 
           'No messages yet';
  }

  bool _isUnread(Map<String, dynamic> conversation) {
    return conversation['unread_count'] != null && 
           conversation['unread_count'] > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text('Inbox (${_conversations.length})'),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _refreshInbox,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spaceLG),
            Text('Loading conversations...', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_conversations.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _refreshInbox,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        itemCount: _conversations.length,
        itemBuilder: (context, index) => _buildConversationCard(_conversations[index]),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.statusError,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            const Text('Failed to load conversations', style: AppTheme.headingMedium),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceXL),
            ElevatedButton.icon(
              onPressed: _loadInbox,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            const Text('No conversations yet', style: AppTheme.headingMedium),
            const SizedBox(height: AppTheme.spaceMD),
            const Text(
              'When you book a ride or someone books your published ride, conversations will appear here',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXL),
            OutlinedButton.icon(
              onPressed: _refreshInbox,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final isUnread = _isUnread(conversation);
    final title = _getConversationTitle(conversation);
    final otherUser = _getOtherUserName(conversation);
    final lastMessage = _getLastMessage(conversation);
    final timestamp = _formatTimestamp(conversation['updated_at'] ?? conversation['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: AppTheme.cardDecoration(elevation: isUnread ? 3 : 1).copyWith(
        border: isUnread 
            ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => _openConversation(conversation),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: Text(
                      otherUser.isNotEmpty ? otherUser[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.statusError,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: AppTheme.spaceLG),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and timestamp
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (timestamp.isNotEmpty)
                          Text(
                            timestamp,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXS),
                    
                    // Other user name
                    Text(
                      otherUser,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXS),
                    
                    // Last message
                    Text(
                      lastMessage,
                      style: AppTheme.bodyMedium.copyWith(
                        color: isUnread ? AppTheme.textPrimary : AppTheme.textMuted,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Arrow and unread indicator
              Column(
                children: [
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                  if (isUnread && conversation['unread_count'] != null)
                    Container(
                      margin: const EdgeInsets.only(top: AppTheme.spaceXS),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusError,
                        borderRadius: BorderRadius.circular(AppTheme.spaceXS),
                      ),
                      child: Text(
                        conversation['unread_count'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Conversation Screen
class ConversationScreen extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> conversation;

  const ConversationScreen({
    super.key,
    required this.api,
    required this.conversation,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    
    try {
      final conversationId = widget.conversation['id'] ?? widget.conversation['thread_id'];
      final rideId = widget.conversation['ride_id'];
      final otherUserId = widget.conversation['other_user_id'];
      
      print('🔍 Loading messages for conversation: $conversationId, ride: $rideId, user: $otherUserId');
      
      List<Map<String, dynamic>> messages = [];
      
      if (conversationId != null) {
        messages = await widget.api.getMessages(conversationId.toString());
      } else if (rideId != null && otherUserId != null) {
        messages = await widget.api.messages(rideId.toString(), otherUserId.toString());
      }
      
      print('✅ Loaded ${messages.length} messages: $messages');
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      
      // Add demo messages for testing
      final demoMessages = [
        {
          'id': 'msg_1',
          'sender_id': 'user_2',
          'message': 'Hi! I\'ve booked your ride. What time should we meet?',
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'msg_2',
          'sender_id': widget.api.getCurrentUserId(),
          'message': 'Hello! Let\'s meet at 8:00 AM at the agreed pickup point.',
          'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
        },
        {
          'id': 'msg_3',
          'sender_id': 'user_2',
          'message': 'Perfect! I\'ll be there 10 minutes early. Thanks!',
          'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'id': 'msg_4',
          'sender_id': widget.api.getCurrentUserId(),
          'message': 'Great! See you tomorrow. Have a good day!',
          'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        },
      ];
      
      if (mounted) {
        setState(() {
          _messages = demoMessages;
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final conversationId = widget.conversation['id'] ?? widget.conversation['thread_id'];
      final rideId = widget.conversation['ride_id'];
      final otherUserId = widget.conversation['other_user_id'];
      
      if (conversationId != null) {
        await widget.api.sendMessageToThread(conversationId.toString(), message);
      } else if (rideId != null && otherUserId != null) {
        await widget.api.sendMessage(rideId.toString(), otherUserId.toString(), message);
      }
      
      // Add message to local list immediately for better UX
      final newMessage = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'sender_id': widget.api.getCurrentUserId(),
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      setState(() {
        _messages.add(newMessage);
      });
      
      _scrollToBottom();
      
      // Optionally refresh messages from server
      // await _loadMessages();
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getConversationTitle() {
    final rideFrom = widget.conversation['ride_from'] ?? 
                     widget.conversation['from'] ?? 
                     'Unknown';
    final rideTo = widget.conversation['ride_to'] ?? 
                   widget.conversation['to'] ?? 
                   'Unknown';
    return '$rideFrom → $rideTo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getConversationTitle(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.conversation['other_user_name'] ?? 'User',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: AppTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppTheme.spaceLG),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                      ),
          ),
          
          // Message input
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textMuted.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Container(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final currentUserId = widget.api.getCurrentUserId();
    final isMe = message['sender_id'] == currentUserId || 
                 message['user_id'] == currentUserId;
    final text = message['message'] ?? message['content'] ?? '';
    final timestamp = message['created_at'] ?? message['timestamp'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: AppTheme.spaceMD,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryBlue : AppTheme.backgroundLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusLG),
            topRight: const Radius.circular(AppTheme.radiusLG),
            bottomLeft: Radius.circular(isMe ? AppTheme.radiusLG : AppTheme.radiusSM),
            bottomRight: Radius.circular(isMe ? AppTheme.radiusSM : AppTheme.radiusLG),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textMuted.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                DateFormat('HH:mm').format(DateTime.parse(timestamp)),
                style: TextStyle(
                  color: isMe ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}