import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/core/widgets/chugli_drawer.dart';
import 'package:chugli_project65/features/rooms/create_room_screen.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
import 'package:chugli_project65/data/services/location_service.dart';
import 'package:chugli_project65/features/rooms/room_conversation_screen.dart';
import 'package:chugli_project65/data/services/mute_service.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  String _selectedRadius = '0.5km';
  String _selectedCategory = '🌟 All';
  List<String> _mutedRoomIds = [];

  static const _predefinedCategories = {
    'Question', 'Help', 'Funny', 'Confession', 'Food', 'Networking', 'College',
  };

  final List<String> _radiusOptions = ['0.5km', '1km', '2km', '5km'];
  final List<String> _categories = [
    '🌟 All',
    '🔥 Active',
    '❓ Questions',
    '😂 Funny',
    '🆘 Help',
    '🤝 Networking',
    '🎤 Confessions',
    '🍕 Food',
    '🎓 College',
    '📂 Others'
  ];

  @override
  void initState() {
    super.initState();
    _loadMutedRooms();
    _loadRadius();
    _fetchLocation();
  }

  Future<void> _loadMutedRooms() async {
    final ids = await MuteService.instance.getMutedRoomIds();
    if (mounted) setState(() => _mutedRoomIds = ids);
  }

  Future<void> _fetchLocation() async {
    await LocationService.instance.getCurrentLocation();
    // Trigger a rebuild so the radius filter applies once GPS is ready.
    if (mounted) setState(() {});
    
    FirestoreRoomService.instance.syncUserLocationAndNotifications();
  }

  Future<void> _loadRadius() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedRadius = prefs.getString('selected_radius') ?? '0.5km';
      });
    }
  }

  Future<void> _saveRadius(String radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_radius', radius);
    if (mounted) {
      setState(() {
        _selectedRadius = radius;
      });
    }
    FirestoreRoomService.instance.syncUserLocationAndNotifications();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Re-fetch GPS on pull-to-refresh
    await _loadMutedRooms();
    await LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() {}); // trigger rebuild to apply new GPS position to filter
      HapticFeedback.lightImpact();
    }
    
    FirestoreRoomService.instance.syncUserLocationAndNotifications();
  }

  void _showRoomOptions(BuildContext context, Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('React'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: const Text('Mute User Locally'),
              onTap: () async {
                Navigator.pop(context);
                await MuteService.instance.muteRoom(
                  id: room['id'] ?? '',
                  title: room['title'] ?? room['preview'] ?? 'Unknown Room',
                  category: room['category'] ?? 'Active',
                );
                await _loadMutedRooms();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room muted successfully.')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ChugliDrawer(
        onRadiusChanged: _loadRadius,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: 200,
        color: const Color(0xFF6C47FF),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(),
            _buildCategoryStrip(),
            _buildFeedList(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6C47FF), Color(0xFF7B61FF)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      Text(
                        "ChugLi",
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded, color: Color(0xFF6C47FF), size: 28),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateRoomScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        "Location Radius",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).cardColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline, color: Colors.white, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildRadiusFilter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: _radiusOptions.map((option) {
          bool isSelected = _selectedRadius == option;
          return Expanded(
            child: GestureDetector(
              onTap: () => _saveRadius(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 20),
            child: Text(
              "Categories",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                Color color;
                if (category.contains('All')) {
                  color = const Color(0xFF6C47FF);
                } else if (category.contains('Active')) {
                  color = const Color(0xFFFF7A59);
                } else if (category.contains('Questions')) {
                  color = const Color(0xFF5B8CFF);
                } else if (category.contains('Funny')) {
                  color = const Color(0xFFFFC83D);
                } else if (category.contains('Help')) {
                  color = const Color(0xFFFF6B6B);
                } else if (category.contains('Networking')) {
                  color = const Color(0xFF00C48C);
                } else if (category.contains('Confessions')) {
                  color = const Color(0xFF8B5CF6);
                } else if (category.contains('Food')) {
                  color = const Color(0xFFFF9F43);
                } else if (category.contains('Others')) {
                  color = const Color(0xFF78909C);
                } else {
                  color = Colors.grey;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? color.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreRoomService.instance.roomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF))),
              ),
            );
          }
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Could not load rooms.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${snapshot.error}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }

          final rooms = snapshot.data ?? [];
          final nonMutedRooms = rooms.where((room) => !_mutedRoomIds.contains(room['id'])).toList();
          final double maxRadius =
              double.tryParse(_selectedRadius.replaceAll('km', '')) ?? 0.5;
          final userPos = LocationService.instance.lastPosition;

          // Filter by GPS radius with safe type casting
          final radiusFiltered = nonMutedRooms.where((room) {
            final lat = (room['latitude'] as num?)?.toDouble();
            final lon = (room['longitude'] as num?)?.toDouble();
            if (userPos == null || lat == null || lon == null) return true;
            return LocationService.instance
                    .distanceInKm(userPos.latitude, userPos.longitude, lat, lon) <=
                maxRadius;
          }).toList();

          // Filter by category
          final filtered = radiusFiltered.where((room) {
            if (_selectedCategory.contains('All')) return true;

            final roomCategory = room['category'] ?? 'Active';

            // "Others" = show rooms NOT in any predefined category
            if (_selectedCategory.contains('Others')) {
              return !_predefinedCategories.contains(roomCategory);
            }

            // Handle plural matches from home categories to singular saved room categories
            if (roomCategory == 'Question' && _selectedCategory.contains('Questions')) return true;
            if (roomCategory == 'Confession' && _selectedCategory.contains('Confessions')) return true;

            return _selectedCategory.contains(roomCategory);
          }).toList();

          if (filtered.isEmpty) {
            if (radiusFiltered.isNotEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Text('📂', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text('No rooms available in this category.',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(
                    children: [
                      Text('🌐', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('No rooms nearby.',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      SizedBox(height: 8),
                      Text('Be the first — create one! 🎉',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final room = filtered[index];
                return _RoomCard(
                  room: room,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomConversationScreen(roomId: room['id']),
                      ),
                    );
                  },
                  onLongPress: () => _showRoomOptions(context, room),
                );
              },
              childCount: filtered.length,
            ),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatefulWidget {
  final Map<String, dynamic> room;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RoomCard({
    required this.room,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second so the countdown stays live
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isHighActivity = widget.room['isHighActivity'] ?? false;
    String category = widget.room['category'] ?? 'Active';

    // Calculate remaining time from absolute expiresAt
    final DateTime expiresAt = widget.room['expiresAt'] ?? DateTime.now().add(const Duration(hours: 2));
    Duration remaining = expiresAt.difference(DateTime.now());

    String remainingText;
    if (remaining.isNegative) {
      remainingText = 'Expired';
    } else if (remaining.inHours > 0) {
      remainingText = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m ${remaining.inSeconds.remainder(60)}s';
    } else if (remaining.inMinutes > 0) {
      remainingText = '${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s';
    } else {
      remainingText = '${remaining.inSeconds}s';
    }

    Color badgeColor;
    switch (category) {
      case 'Question': badgeColor = const Color(0xFF5B8CFF); break;
      case 'Funny': badgeColor = const Color(0xFFFFC83D); break;
      case 'Help': badgeColor = const Color(0xFFFF6B6B); break;
      case 'Networking': badgeColor = const Color(0xFF00C48C); break;
      case 'Confessions': badgeColor = const Color(0xFF8B5CF6); break;
      case 'Active': badgeColor = const Color(0xFFFF7A59); break;
      case 'Food': badgeColor = const Color(0xFFFF9F43); break;
      case 'College': badgeColor = const Color(0xFF26A69A); break;
      default:
        badgeColor = const Color(0xFF78909C); // blue-grey for custom categories
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(isHighActivity ? 24 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge(category, badgeColor),
                      if (!remaining.isNegative && remaining.inMinutes < 15)
                        _buildBadge("Expires Soon", Colors.orange, icon: Icons.timer_outlined),
                    ],
                  ),
                ),
                if (isHighActivity)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildBadge("High Activity", const Color(0xFFFF8A80), icon: Icons.bolt_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.room['preview'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4A4A4A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.room['title'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B4B9A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLiveIndicator(),
                const SizedBox(width: 12),
                Text(
                  "${widget.room['participants'] ?? 0} Participants",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A4A4A)),
                ),
                const Spacer(),
                // ── Feature 2: Live countdown ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    remainingText,
                    key: ValueKey(remainingText),
                    style: TextStyle(
                      color: remaining.isNegative
                          ? Colors.red
                          : remaining.inMinutes < 5
                              ? Colors.orange
                              : Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: remaining.isNegative
                      ? Colors.red
                      : remaining.inMinutes < 5
                          ? Colors.orange
                          : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReactionStack(context, List<String>.from(widget.room['reactions'] ?? [])),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildReactionStack(BuildContext context, List<String> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: reactions.map((r) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Text(r, style: const TextStyle(fontSize: 14)),
      )).toList(),
    );
  }
}


