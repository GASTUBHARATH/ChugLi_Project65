import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
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
  int _lastMessageCount = 0;

  // The current user's Firebase UID — used to identify "my" messages.
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? _selectedTag;

  final List<String> _tags = [
    'Question', 'Help', 'Confession', 'Advice', 'Funny', 'Poll', 'Networking', 'Recommendation'
  ];

  final List<String> _emojis = ['😂', '❤️', '🔥', '👍', '😢', '😮', '😡', '💯'];

  late final Stream<Map<String, dynamic>?> _roomStream;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _roomStream = FirestoreRoomService.instance.roomStream(widget.roomId);
    _messagesStream = FirestoreRoomService.instance.messagesStream(widget.roomId);

    // Automatically join the room when entering
    FirestoreRoomService.instance.joinRoom(widget.roomId).catchError((e) {
      debugPrint('Error joining room: $e');
    });

    // Rebuild every second so the countdown timer stays accurate.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    if (mounted) setState(() => _selectedTag = null);

    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('userHandle') ?? 'Anonymous';

    try {
      await FirestoreRoomService.instance.sendMessage(
        roomId: widget.roomId,
        handle: handle,
        text: text,
        tag: _selectedTag,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Emojis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _emojis.map((e) => GestureDetector(
                    onTap: () {
                      _messageController.text += e;
                      Navigator.pop(context);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 32)),
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
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _emojis.map((e) => GestureDetector(
                onTap: () {
                  FirestoreRoomService.instance.addReaction(widget.roomId, messageId, e);
                  Navigator.pop(context);
                },
                child: Text(e, style: const TextStyle(fontSize: 32)),
              )).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        final room = snapshot.data;

        if (room == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF))),
          );
        }

        final DateTime expiresAt =
            room['expiresAt'] ?? DateTime.now().add(const Duration(hours: 2));
        Duration remaining = expiresAt.difference(DateTime.now());
        bool isExpired = remaining.isNegative;

        return Scaffold(
          appBar: _buildAppBar(room, remaining),
          body: Stack(
            children: [
              Column(
                children: [
                  if (!isExpired && remaining.inMinutes < 15) _buildExpiryWarning(),
                  Expanded(child: _buildMessageList(widget.roomId, room)),
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
    final int participantCount = room['participants'] as int? ?? 1;
    String remainingText = remaining.isNegative
        ? 'Expired'
        : remaining.inHours > 0
            ? '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m remaining'
            : '${remaining.inMinutes}m remaining';

    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room['title'] ?? 'Room',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '$participantCount ${participantCount == 1 ? "person" : "people"} joined',
                style: const TextStyle(color: Color(0xFF6C47FF), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                remainingText,
                style: TextStyle(
                    color: remaining.isNegative ? Colors.red : Colors.grey.shade600,
                    fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessageList(String roomId, Map<String, dynamic> room) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load messages.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF)));
        }
        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🗨️', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text('No messages yet.\nBe the first to say something!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        // Auto-scroll when new messages arrive
        if (messages.length > _lastMessageCount) {
          _lastMessageCount = messages.length;
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
        
        final List<String> participantUids = List<String>.from(room['participantUids'] ?? []);
        return _buildMessageListView(messages, participantUids);
      },
    );
  }

  Widget _buildMessageListView(List<Map<String, dynamic>> messages, List<String> participantUids) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];

        // ✅ CORRECT: compare Firebase UID stored in the message.
        final bool isMe = (msg['uid'] as String?) == _myUid && _myUid.isNotEmpty;

        final DateTime ts = msg['timestamp'] ?? DateTime.now();
        final String timeStr =
            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe) ...[
                      Text(
                        participantUids.contains(msg['uid']) ? (msg['handle'] ?? 'Anonymous') : 'Deleted User',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(timeStr,
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      const Text('You',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: () {
                    HapticFeedback.lightImpact();
                    _addReaction(msg['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF6C47FF)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg['tag'] != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withOpacity(0.2)
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              msg['tag'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF6C47FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : (Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black87),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if ((msg['reactions'] as List? ?? []).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: _buildReactionChips(
                        context,
                        List<String>.from(msg['reactions'] ?? [])),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildReactionChips(BuildContext context, List<String> reactions) {
    final Map<String, int> counts = {};
    for (final r in reactions) {
      counts[r] = (counts[r] ?? 0) + 1;
    }

    return counts.entries.map((e) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.key, style: const TextStyle(fontSize: 12)),
          if (e.value > 1) ...[
            const SizedBox(width: 2),
            Text(e.value.toString(),
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    )).toList();
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTag != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  label: Text(_selectedTag!),
                  onDeleted: () => setState(() => _selectedTag = null),
                  backgroundColor:
                      const Color(0xFF6C47FF).withOpacity(0.1),
                  labelStyle: const TextStyle(
                      color: Color(0xFF6C47FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  deleteIconColor: const Color(0xFF6C47FF),
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.grey),
                  onPressed: _showEmojiPicker,
                ),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
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
                  icon: const Icon(Icons.local_offer_outlined,
                      color: Colors.grey),
                  onPressed: _showTagSelector,
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C47FF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFFB74D).withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This room expires in less than 15 minutes!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_off_rounded,
                    color: Colors.red, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'This conversation has ended.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start a new one nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateRoomScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create Room',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
