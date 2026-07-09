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
  static const _secureChannel = MethodChannel('com.chugli.app/secure');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  int _lastMessageCount = 0;
  bool _isBanned = false;
  bool _banChecked = false;

  // Cached streams — NEVER recreate inside build/setState
  late final Stream<Map<String, dynamic>?> _roomStream;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  // The current user's Firebase UID
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? _selectedTag;

  final List<String> _tags = [
    'Question', 'Help', 'Confession', 'Advice', 'Funny', 'Poll', 'Networking', 'Recommendation'
  ];

  final List<String> _emojis = ['😂', '❤️', '🔥', '👍', '😢', '😮', '😡', '💯'];

  // ── Feature 13: Swipe-to-Reply state ─────────────────────────────
  Map<String, dynamic>? _replyToMsg;

  // ── Feature 4: Poll creation state ───────────────────────────────
  bool _isPollMode = false;
  final TextEditingController _pollQuestionCtrl = TextEditingController();
  final List<TextEditingController> _pollOptionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _secureChannel.invokeMethod('enableSecureMode');

    _roomStream = FirestoreRoomService.instance.roomStream(widget.roomId);
    _messagesStream = FirestoreRoomService.instance.messagesStream(widget.roomId);

    // Check if user is banned from this room
    _checkBanStatus();

    // Rebuild every second so countdown stays accurate
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkBanStatus() async {
    try {
      final banned = await FirestoreRoomService.instance.isUserBanned(widget.roomId);
      if (mounted) setState(() { _isBanned = banned; _banChecked = true; });
    } catch (_) {
      if (mounted) setState(() { _banChecked = true; });
    }
  }

  @override
  void dispose() {
    _secureChannel.invokeMethod('disableSecureMode');
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _pollQuestionCtrl.dispose();
    for (final c in _pollOptionCtrls) { c.dispose(); }
    super.dispose();
  }

  void _sendMessage() async {
    if (_isBanned) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final replyTo = _replyToMsg;
    if (mounted) setState(() { _selectedTag = null; _replyToMsg = null; });

    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('userHandle') ?? 'Anonymous';

    try {
      await FirestoreRoomService.instance.sendMessage(
        roomId: widget.roomId,
        handle: handle,
        text: text,
        tag: _selectedTag,
        replyTo: replyTo != null
            ? {'handle': replyTo['handle'] ?? 'User', 'text': replyTo['text'] ?? ''}
            : null,
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

  // ── Feature 4: Send a poll ────────────────────────────────────────
  void _sendPoll() async {
    if (_isBanned) return;
    final question = _pollQuestionCtrl.text.trim();
    if (question.isEmpty) return;
    final opts = _pollOptionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (opts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 options.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    _pollQuestionCtrl.clear();
    for (final c in _pollOptionCtrls) { c.clear(); }
    if (mounted) setState(() => _isPollMode = false);

    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('userHandle') ?? 'Anonymous';

    try {
      await FirestoreRoomService.instance.sendPollMessage(
        roomId: widget.roomId,
        handle: handle,
        question: question,
        options: opts,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send poll: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── Long-press message options: React / Reply / Copy / Pin / Report ──
  void _showMessageOptions(Map<String, dynamic> msg, {required bool isCreator}) {
    final bool isMe = (msg['uid'] as String?) == _myUid && _myUid.isNotEmpty;
    final bool isPoll = msg['type'] == 'poll';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Feature 1: React ──
              if (!isPoll)
                ListTile(
                  leading: const Text('😀', style: TextStyle(fontSize: 22)),
                  title: const Text('React', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReactionPicker(msg);
                  },
                ),
              // Reply (existing, now also sets _replyToMsg)
              if (!isPoll)
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: Color(0xFF6C47FF)),
                  title: const Text('Reply', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _replyToMsg = msg);
                  },
                ),
              // Copy Message
              if (!isPoll)
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Colors.grey),
                  title: const Text('Copy Message', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              // ── Feature 5: Pin Message (creator only, non-poll) ──
              if (isCreator && !isPoll)
                ListTile(
                  leading: const Icon(Icons.push_pin_rounded, color: Color(0xFFFFC83D)),
                  title: const Text('Pin Message', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await FirestoreRoomService.instance.pinMessage(
                        roomId: widget.roomId,
                        messageId: msg['id'] ?? '',
                        text: msg['text'] ?? '',
                        handle: msg['handle'] ?? 'Anonymous',
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not pin: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                ),
              // Report — only available for messages from OTHER users
              if (!isMe)
                ListTile(
                  leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
                  title: const Text(
                    'Report User',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog(msg);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Feature 1: Reaction picker ────────────────────────────────────
  void _showReactionPicker(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Text('React', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _emojis.map((emoji) {
                  final reactionsMap = Map<String, dynamic>.from(msg['reactionsMap'] ?? {});
                  final uids = List<String>.from(reactionsMap[emoji] ?? []);
                  final reacted = uids.contains(_myUid);
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      HapticFeedback.lightImpact();
                      try {
                        await FirestoreRoomService.instance.addMessageReaction(
                          widget.roomId, msg['id'] ?? '', emoji,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('React failed: $e'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: reacted ? const Color(0xFF6C47FF).withValues(alpha: 0.15) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: reacted ? Border.all(color: const Color(0xFF6C47FF), width: 1.5) : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(Map<String, dynamic> msg) {
    String? selectedReason;
    final reasons = [
      'Spam or irrelevant content',
      'Harassment or bullying',
      'Hate speech or discrimination',
      'Explicit or inappropriate content',
      'Impersonation',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    msg['handle'] ?? 'Anonymous',
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: RadioGroup<String>(
              groupValue: selectedReason ?? '',
              onChanged: (val) => setDialogState(() => selectedReason = val),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  activeColor: const Color(0xFF6C47FF),
                )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null ? null : () async {
                Navigator.pop(ctx);
                await _submitReport(msg, selectedReason!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(Map<String, dynamic> msg, String reason) async {
    try {
      await FirestoreRoomService.instance.reportUser(
        roomId: widget.roomId,
        reportedUid: msg['uid'] ?? '',
        reportedHandle: msg['handle'] ?? 'Anonymous',
        messageText: msg['text'] ?? '',
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Report submitted. We\'ll review it.'),
            ]),
            backgroundColor: const Color(0xFF6C47FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
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
                      selectedColor: const Color(0xFF6C47FF).withValues(alpha: 0.2),
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

  @override
  Widget build(BuildContext context) {
    return _buildSecureScreen();
  }

  Widget _buildSecureScreen() {
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

        final bool isCreator = (room['createdBy'] as String?) == _myUid && _myUid.isNotEmpty;
        final pinnedMsg = room['pinnedMessage'] as Map<String, dynamic>?;

        return Scaffold(
          appBar: _buildAppBar(room, remaining),
          body: Stack(
            children: [
              Column(
                children: [
                  if (!isExpired && remaining.inMinutes < 15) _buildExpiryWarning(),
                  // ── Feature 5: Pinned message banner ──
                  if (pinnedMsg != null) _buildPinnedBanner(pinnedMsg, isCreator),
                  // Banned notice replaces message list and input
                  if (_banChecked && _isBanned)
                    _buildBannedNotice()
                  else ...[
                    Expanded(child: _buildMessageList(isCreator)),
                    if (!isExpired) _buildChatInput(),
                  ],
                ],
              ),
              if (isExpired && !_isBanned) _buildExpiredOverlay(),
            ],
          ),
        );
      },
    );
  }

  // ── Feature 5: Pinned message banner ─────────────────────────────
  Widget _buildPinnedBanner(Map<String, dynamic> pinnedMsg, bool isCreator) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC83D).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin_rounded, size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pinnedMsg['handle'] ?? 'Anonymous',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                ),
                Text(
                  pinnedMsg['text'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
                ),
              ],
            ),
          ),
          if (isCreator)
            GestureDetector(
              onTap: () async {
                try {
                  await FirestoreRoomService.instance.unpinMessage(widget.roomId);
                } catch (_) {}
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannedNotice() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'ve been removed\nfrom this room',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'The majority of participants reported your messages in this room. You can still use ChugLi and join other rooms.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              label: const Text('Back to Feed',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildMessageList(bool isCreator) {
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
        return _buildMessageListView(messages, isCreator);
      },
    );
  }

  Widget _buildMessageListView(List<Map<String, dynamic>> messages, bool isCreator) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final bool isMe = (msg['uid'] as String?) == _myUid && _myUid.isNotEmpty;
        final DateTime ts = msg['timestamp'] ?? DateTime.now();
        final String timeStr =
            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
        final bool isPoll = msg['type'] == 'poll';

        // ── Feature 13: Swipe-to-reply wrapper ──
        return _SwipeToReplyWrapper(
          onSwipe: () {
            if (!isPoll) {
              HapticFeedback.mediumImpact();
              setState(() => _replyToMsg = msg);
            }
          },
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe) ...[
                        Text(
                          msg['handle'] ?? 'Anonymous',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        const Text('You', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Render poll or normal message
                  if (isPoll)
                    _buildPollMessage(msg, isMe)
                  else
                    GestureDetector(
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showMessageOptions(msg, isCreator: isCreator);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF6C47FF) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Feature 13: Show reply quote ──
                            if (msg['replyTo'] != null) ...[
                              _buildReplyQuoteBlock(msg['replyTo'] as Map<String, dynamic>, isMe),
                              const SizedBox(height: 8),
                            ],
                            if (msg['tag'] != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.white.withValues(alpha: 0.2) : Theme.of(context).scaffoldBackgroundColor,
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
                              const SizedBox(height: 8),
                            ],
                            Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // ── Feature 1: Reactions row ──
                  if (!isPoll) ...[
                    const SizedBox(height: 4),
                    _buildReactionChips(context, msg),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Feature 13: Quoted block inside bubble ────────────────────────
  Widget _buildReplyQuoteBlock(Map<String, dynamic> replyTo, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF6C47FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6C47FF),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyTo['handle'] ?? 'User',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF6C47FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyTo['text'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white.withValues(alpha: 0.75) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature 4: Poll message widget ───────────────────────────────
  Widget _buildPollMessage(Map<String, dynamic> msg, bool isMe) {
    final question = msg['question'] as String? ?? 'Poll';
    final rawOptions = msg['options'] as List? ?? [];
    final options = rawOptions.map((o) => Map<String, dynamic>.from(o as Map)).toList();
    final totalVotes = options.fold<int>(0, (sum, o) {
      final votes = o['votes'] as List? ?? [];
      return sum + votes.length;
    });

    // Find which option the current user voted for
    int? myVoteIndex;
    for (int i = 0; i < options.length; i++) {
      final votes = List<String>.from(options[i]['votes'] ?? []);
      if (votes.contains(_myUid)) { myVoteIndex = i; break; }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C47FF).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text('POLL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6C47FF), letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final opt = options[i];
            final optText = opt['text'] as String? ?? 'Option ${i + 1}';
            final votes = List<String>.from(opt['votes'] ?? []);
            final voteCount = votes.length;
            final pct = totalVotes == 0 ? 0.0 : voteCount / totalVotes;
            final isMyVote = myVoteIndex == i;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  try {
                    await FirestoreRoomService.instance.votePoll(
                      roomId: widget.roomId,
                      messageId: msg['id'] ?? '',
                      optionIndex: i,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vote failed: $e'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMyVote
                        ? const Color(0xFF6C47FF).withValues(alpha: 0.12)
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMyVote ? const Color(0xFF6C47FF) : Colors.grey.withValues(alpha: 0.3),
                      width: isMyVote ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              optText,
                              style: TextStyle(
                                fontWeight: isMyVote ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                color: isMyVote ? const Color(0xFF6C47FF) : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (isMyVote)
                            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF6C47FF)),
                          const SizedBox(width: 4),
                          Text(
                            '$voteCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMyVote ? const Color(0xFF6C47FF) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMyVote ? const Color(0xFF6C47FF) : Colors.grey.shade400,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '$totalVotes vote${totalVotes == 1 ? "" : "s"}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Feature 1: Reaction chips below a message ────────────────────
  Widget _buildReactionChips(BuildContext context, Map<String, dynamic> msg) {
    final reactionsMap = Map<String, dynamic>.from(msg['reactionsMap'] ?? {});

    // Also show legacy flat reactions (old data)
    final legacyList = List<String>.from(msg['reactions'] ?? []);
    for (final emoji in legacyList) {
      if (!reactionsMap.containsKey(emoji)) {
        reactionsMap[emoji] = <String>[];
      }
    }

    if (reactionsMap.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactionsMap.entries.map((e) {
        final uids = List<String>.from(e.value as List? ?? []);
        final count = uids.isNotEmpty ? uids.length : (legacyList.where((l) => l == e.key).length);
        final myReacted = uids.contains(_myUid);
        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              await FirestoreRoomService.instance.addMessageReaction(
                widget.roomId, msg['id'] ?? '', e.key,
              );
            } catch (_) {}
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: myReacted
                  ? const Color(0xFF6C47FF).withValues(alpha: 0.12)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: myReacted ? const Color(0xFF6C47FF) : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: myReacted ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 13)),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: myReacted ? const Color(0xFF6C47FF) : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Feature 13: Reply quote above input ──
            if (_replyToMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: const Color(0xFF6C47FF), width: 3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _replyToMsg!['handle'] ?? 'User',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6C47FF)),
                            ),
                            Text(
                              _replyToMsg!['text'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyToMsg = null),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedTag != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  label: Text(_selectedTag!),
                  onDeleted: () => setState(() => _selectedTag = null),
                  backgroundColor: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                      color: Color(0xFF6C47FF), fontSize: 12, fontWeight: FontWeight.bold),
                  deleteIconColor: const Color(0xFF6C47FF),
                ),
              ),
            // ── Feature 4: Poll creation panel ──
            if (_isPollMode) _buildPollCreationPanel(),
            if (!_isPollMode)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                    onPressed: _showEmojiPicker,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    icon: const Icon(Icons.local_offer_outlined, color: Colors.grey),
                    onPressed: _showTagSelector,
                  ),
                  // ── Feature 4: Poll toggle button ──
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: _isPollMode ? const Color(0xFF6C47FF) : Colors.grey,
                    ),
                    onPressed: () => setState(() { _isPollMode = !_isPollMode; }),
                    tooltip: 'Create Poll',
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C47FF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  // ── Feature 4: Poll creation panel ───────────────────────────────
  Widget _buildPollCreationPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C47FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text('Create a Poll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6C47FF))),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isPollMode = false),
                child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pollQuestionCtrl,
            decoration: InputDecoration(
              hintText: 'Ask a question...',
              hintStyle: const TextStyle(fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C47FF))),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (ctx, setLocal) => Column(
              children: [
                ...List.generate(_pollOptionCtrls.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pollOptionCtrls[i],
                          decoration: InputDecoration(
                            hintText: 'Option ${i + 1}',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C47FF))),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_pollOptionCtrls.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setLocal(() {
                              _pollOptionCtrls[i].dispose();
                              _pollOptionCtrls.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                )),
                if (_pollOptionCtrls.length < 4)
                  TextButton.icon(
                    onPressed: () => setLocal(() => _pollOptionCtrls.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C47FF)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendPoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Send Poll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This room expires in less than 15 minutes!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_off_rounded, color: Colors.red, size: 48),
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
                      MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create Room',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature 13: Swipe-to-Reply gesture wrapper ────────────────────
class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;

  const _SwipeToReplyWrapper({required this.child, required this.onSwipe});

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper> {
  double _dragOffset = 0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0) {
          setState(() {
            _dragOffset = (_dragOffset + details.delta.dx).clamp(0, 72);
          });
          if (_dragOffset >= 60 && !_triggered) {
            _triggered = true;
            widget.onSwipe();
          }
        }
      },
      onHorizontalDragEnd: (_) {
        setState(() { _dragOffset = 0; _triggered = false; });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
          if (_dragOffset > 10)
            Positioned(
              left: _dragOffset - 36,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: (_dragOffset / 60).clamp(0, 1),
                  duration: const Duration(milliseconds: 80),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C47FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.reply_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
