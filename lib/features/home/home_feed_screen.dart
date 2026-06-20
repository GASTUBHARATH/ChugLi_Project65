import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/core/widgets/chugli_drawer.dart';
import 'package:chugli_project65/features/rooms/create_room_screen.dart';
import 'package:chugli_project65/data/services/room_data_service.dart';
import 'package:chugli_project65/features/rooms/room_conversation_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  String _selectedRadius = '0.5km';
  String _selectedCategory = '🔥 Active';
  bool _isLoading = false;
  Timer? _refreshTimer;

  final List<String> _radiusOptions = ['0.5km', '1km', '2km', '5km'];
  final List<String> _categories = [
    '🔥 Active',
    '❓ Questions',
    '😂 Funny',
    '🆘 Help',
    '🤝 Networking',
    '🎤 Confessions',
    '🍕 Food',
    '🎓 College'
  ];

  @override
  void initState() {
    super.initState();
    _loadRadius();
    _startAutoRefresh();
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
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _handleRefresh();
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
    }
  }

  void _showRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: Icon(Icons.add_reaction_outlined),
              title: Text('React'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.report_problem, color: Colors.red),
              title: Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.volume_off_outlined),
              title: Text('Mute User Locally'),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 12),
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
        height: 200,
        decoration: BoxDecoration(
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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu_rounded, color: Colors.white, size: 28),
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
                        icon: Icon(Icons.add_rounded, color: Color(0xFF6C47FF), size: 28),
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
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
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
                    SizedBox(width: 4),
                    Icon(Icons.info_outline, color: Colors.white, size: 14),
                  ],
                ),
              ),
              SizedBox(height: 8),
              _buildRadiusFilter(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusFilter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
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
                padding: EdgeInsets.symmetric(vertical: 8),
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
            padding: EdgeInsets.only(left: 24, top: 20),
            child: Text(
              "Categories",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                Color color;
                if (category.contains('Active')) color = const Color(0xFFFF7A59);
                else if (category.contains('Questions')) color = const Color(0xFF5B8CFF);
                else if (category.contains('Funny')) color = const Color(0xFFFFC83D);
                else if (category.contains('Help')) color = const Color(0xFFFF6B6B);
                else if (category.contains('Networking')) color = const Color(0xFF00C48C);
                else if (category.contains('Confessions')) color = const Color(0xFF8B5CF6);
                else if (category.contains('Food')) color = const Color(0xFFFF9F43);
                else color = Colors.grey;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
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
      padding: EdgeInsets.all(16),
      sliver: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: RoomDataService.instance.roomsNotifier,
        builder: (context, rooms, child) {
          double maxRadius = double.tryParse(_selectedRadius.replaceAll('km', '')) ?? 0.5;

          final activeRooms = rooms.where((room) {
            DateTime createdAt = room['createdAt'] ?? DateTime.now();
            Duration expiryTime = room['expiryTime'] ?? const Duration(hours: 2);
            if (createdAt.add(expiryTime).difference(DateTime.now()).isNegative) return false;

            if (room['distance'] == null) return true;
            double distance = room['distance'] as double;
            return distance <= maxRadius;
          }).toList();

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final room = activeRooms[index];
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
                  onLongPress: () => _showRoomOptions(context),
                );
              },
              childCount: activeRooms.length,
            ),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RoomCard({
    required this.room,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    bool isHighActivity = room['isHighActivity'] ?? false;
    String category = room['category'] ?? 'Active';
    
    // Calculate remaining time
    DateTime createdAt = room['createdAt'] ?? DateTime.now();
    Duration expiryTime = room['expiryTime'] ?? const Duration(hours: 2);
    DateTime expiryDate = createdAt.add(expiryTime);
    Duration remaining = expiryDate.difference(DateTime.now());
    
    String remainingText;
    if (remaining.isNegative) {
      remainingText = 'Expired';
    } else if (remaining.inHours > 0) {
      remainingText = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    } else {
      remainingText = '${remaining.inMinutes}m';
    }

    Color badgeColor;
    switch (category) {
      case 'Question': badgeColor = const Color(0xFF5B8CFF); break;
      case 'Funny': badgeColor = const Color(0xFFFFC83D); break;
      case 'Help': badgeColor = const Color(0xFFFF6B6B); break;
      case 'Networking': badgeColor = const Color(0xFF00C48C); break;
      case 'Confessions': badgeColor = const Color(0xFF8B5CF6); break;
      case 'Active': badgeColor = const Color(0xFFFF7A59); break;
      default: badgeColor = Colors.grey;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(isHighActivity ? 24 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C47FF).withOpacity(0.08),
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
                Row(
                  children: [
                    _buildBadge(category, badgeColor),
                    if (!remaining.isNegative && remaining.inMinutes < 15) ...[
                      SizedBox(width: 8),
                      _buildBadge("Expires Soon", Colors.orange, icon: Icons.timer_outlined),
                    ]
                  ],
                ),
                if (isHighActivity)
                  _buildBadge("High Activity Room", const Color(0xFFFF8A80), icon: Icons.bolt_rounded),
              ],
            ),
            SizedBox(height: 12),
            Text(
              room['preview'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF4A4A4A),
                height: 1.4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              room['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B4B9A),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildLiveIndicator(),
                SizedBox(width: 12),
                Text(
                  "${room['participants']} Participants",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A4A4A)),
                ),
                const Spacer(),
                Text(
                  remainingText,
                  style: TextStyle(color: remaining.isNegative ? Colors.red : Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 4),
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
              ],
            ),
            SizedBox(height: 16),
            _buildReactionStack(context, List<String>.from(room['reactions'] ?? [])),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) SizedBox(width: 4),
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildReactionStack(BuildContext context, List<String> reactions) {
    return Row(
      children: reactions.map((r) => Padding(
        padding: EdgeInsets.only(right: 6),
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
          child: Text(r, style: TextStyle(fontSize: 14)),
        ),
      )).toList(),
    );
  }
}
