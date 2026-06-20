import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/data/services/room_data_service.dart';
import 'package:chugli_project65/features/rooms/create_room_screen.dart';

class RoomConversationScreen extends StatefulWidget {
  final String roomId;
  const RoomConversationScreen({super.key, required this.roomId});

  @override
  State<RoomConversationScreen> createState() => _RoomConversationScreenState();
}

class _RoomConversationScreenState extends State<RoomConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  
  String? _selectedTag;
  
  final List<String> _tags = [
    'Question', 'Help', 'Confession', 'Advice', 'Funny', 'Poll', 'Networking', 'Recommendation'
  ];

  final List<String> _emojis = ['😂', '❤️', '🔥', '👍', '😢', '😮', '😡', '💯'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _room {
    final rooms = RoomDataService.instance.roomsNotifier.value;
    final idx = rooms.indexWhere((r) => r['id'] == widget.roomId);
    if (idx != -1) return rooms[idx];
    return null;
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'handle': 'Anonymous Me', // Dummy handle
      'text': _messageController.text.trim(),
      'timestamp': DateTime.now(),
      'tag': _selectedTag,
      'reactions': <String>[],
    };
    
    RoomDataService.instance.addMessage(widget.roomId, message);
    _messageController.clear();
    setState(() {
      _selectedTag = null;
    });
    
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

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    final isSelected = _selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedTag = val ? tag : null);
                        Navigator.pop(context);
                      },
                      selectedColor: const Color(0xFF6C47FF).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF6C47FF) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Emojis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _emojis.map((e) => GestureDetector(
                    onTap: () {
                      _messageController.text += e;
                      Navigator.pop(context);
                    },
                    child: Text(e, style: TextStyle(fontSize: 32)),
                  )).toList(),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _addReaction(String messageId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _emojis.map((e) => GestureDetector(
                onTap: () {
                  RoomDataService.instance.addReaction(widget.roomId, messageId, e);
                  Navigator.pop(context);
                },
                child: Text(e, style: TextStyle(fontSize: 32)),
              )).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: RoomDataService.instance.roomsNotifier,
      builder: (context, rooms, child) {
        final room = _room;
        if (room == null) return const Scaffold(body: Center(child: Text('Room not found')));

        DateTime createdAt = room['createdAt'] ?? DateTime.now();
        Duration expiryTime = room['expiryTime'] ?? const Duration(hours: 2);
        DateTime expiryDate = createdAt.add(expiryTime);
        Duration remaining = expiryDate.difference(DateTime.now());
        
        bool isExpired = remaining.isNegative;

        return Scaffold(
          appBar: _buildAppBar(room, remaining),
          body: Stack(
            children: [
              Column(
                children: [
                  if (!isExpired && remaining.inMinutes < 15) _buildExpiryWarning(),
                  Expanded(child: _buildMessageList(room['messages'] ?? [])),
                  if (!isExpired) _buildChatInput(),
                ],
              ),
              if (isExpired) _buildExpiredOverlay(),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> room, Duration remaining) {
    String remainingText = remaining.isNegative
        ? 'Expired'
        : remaining.inHours > 0
            ? '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m remaining'
            : '${remaining.inMinutes}m remaining';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room['title'] ?? 'Room',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${room['participants']} Participants',
                style: TextStyle(color: Color(0xFF6C47FF), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text(
                remainingText,
                style: TextStyle(color: remaining.isNegative ? Colors.red : Colors.grey.shade700, fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessageList(List<dynamic> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        bool isMe = msg['handle'] == 'Anonymous Me';
        
        DateTime ts = msg['timestamp'] ?? DateTime.now();
        String timeStr = '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg['handle'],
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(width: 8),
                    Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onLongPress: () {
                    HapticFeedback.lightImpact();
                    _addReaction(msg['id']);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF6C47FF) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg['tag'] != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white.withOpacity(0.2) : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              msg['tag'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : const Color(0xFF6C47FF),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        Text(
                          msg['text'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                if ((msg['reactions'] as List).isNotEmpty) ...[
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: _buildReactionStack(context, List<String>.from(msg['reactions'] ?? [])),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildReactionStack(context, List<String> reactions) {
    Map<String, int> counts = {};
    for (var r in reactions) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    
    return counts.entries.map((e) => Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.key, style: TextStyle(fontSize: 12)),
          if (e.value > 1) ...[
            SizedBox(width: 2),
            Text(e.value.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    )).toList();
  }

  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ]
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTag != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Chip(
                  label: Text(_selectedTag!),
                  onDeleted: () => setState(() => _selectedTag = null),
                  backgroundColor: const Color(0xFF6C47FF).withOpacity(0.1),
                  labelStyle: TextStyle(color: Color(0xFF6C47FF), fontSize: 12, fontWeight: FontWeight.bold),
                  deleteIconColor: const Color(0xFF6C47FF),
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: _showEmojiPicker,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type anonymously...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.local_offer_outlined, color: Colors.grey),
                  onPressed: _showTagSelector,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF6C47FF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryWarning() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Rooms with less than 15 minutes left!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'This room expires soon.',
                  style: TextStyle(color: Color(0xFFE65100), fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpiredOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_off_rounded, color: Colors.red, size: 48),
              ),
              SizedBox(height: 24),
              Text(
                'This conversation has ended.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                'Start a new one nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Create Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
