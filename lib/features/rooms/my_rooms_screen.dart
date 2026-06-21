import 'package:flutter/material.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
import 'package:chugli_project65/features/rooms/room_details_screen.dart';

class MyRoomsScreen extends StatefulWidget {
  const MyRoomsScreen({super.key});

  @override
  State<MyRoomsScreen> createState() => _MyRoomsScreenState();
}

class _MyRoomsScreenState extends State<MyRoomsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Rooms',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreRoomService.instance.myRoomsStream(),
        builder: (context, createdSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreRoomService.instance.joinedRoomsStream(),
            builder: (context, joinedSnapshot) {
              if (createdSnapshot.connectionState == ConnectionState.waiting ||
                  joinedSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF)));
              }

              if (createdSnapshot.hasError || joinedSnapshot.hasError) {
                final error = createdSnapshot.hasError ? createdSnapshot.error : joinedSnapshot.error;
                debugPrint('🔥 Firestore Error in MyRoomsScreen: $error');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading rooms:\n$error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final createdRooms = createdSnapshot.data ?? [];
              final joinedRooms = joinedSnapshot.data ?? [];

              // Calculate unique active rooms and messages count
              final uniqueRooms = <String, Map<String, dynamic>>{};
              for (var room in createdRooms) {
                uniqueRooms[room['id']] = room;
              }
              for (var room in joinedRooms) {
                uniqueRooms[room['id']] = room;
              }

              final int activeCount = uniqueRooms.values.where((r) {
                final exp = r['expiresAt'] as DateTime?;
                return exp != null && exp.isAfter(DateTime.now());
              }).length;

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildStatisticsSection(createdRooms.length, joinedRooms.length, activeCount, 0),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicatorColor: const Color(0xFF6C47FF),
                          labelColor: const Color(0xFF6C47FF),
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Created'),
                            Tab(text: 'Joined'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomList(createdRooms),
                    _buildRoomList(joinedRooms),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection(int created, int joined, int active, int messages) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFFB39DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C47FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Statistics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Created', created.toString()),
              _buildStatItem('Joined', joined.toString()),
              _buildStatItem('Active', active.toString()),
              _buildStatItem('Messages', messages.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRoomList(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No rooms found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 40),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        return _buildRoomCard(rooms[index]);
      },
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final DateTime expiresAt = room['expiresAt'] ?? DateTime.now();
    Duration remaining = expiresAt.difference(DateTime.now());
    bool isExpired = remaining.isNegative;

    String remainingText = isExpired
        ? 'Expired'
        : remaining.inHours > 0
            ? '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left'
            : '${remaining.inMinutes}m left';

    String category = room['category'] ?? 'Active';
    String emoji = '🔥';
    Color iconBgColor = const Color(0xFFFF7A59);
    
    switch (category) {
      case 'Question': emoji = '❓'; iconBgColor = const Color(0xFF5B8CFF); break;
      case 'Funny': emoji = '😂'; iconBgColor = const Color(0xFFFFC83D); break;
      case 'Help': emoji = '🆘'; iconBgColor = const Color(0xFFFF6B6B); break;
      case 'Networking': emoji = '🤝'; iconBgColor = const Color(0xFF00C48C); break;
      case 'Confession': emoji = '🎤'; iconBgColor = const Color(0xFF8B5CF6); break;
      case 'Food': emoji = '🍕'; iconBgColor = const Color(0xFFFF9F43); break;
    }

    final messages = List.from(room['messages'] ?? []);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: 24)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['title'] ?? 'Room',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(color: iconBgColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.grey.withOpacity(0.1) : const Color(0xFF00C48C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isExpired ? 'Expired' : 'Active',
                  style: TextStyle(
                    color: isExpired ? Colors.grey.shade700 : const Color(0xFF00C48C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(Icons.people_alt_rounded, '${room['participants']}', Colors.blue),
              _buildInfoChip(Icons.chat_bubble_rounded, '${messages.length}', Colors.orange),
              _buildInfoChip(Icons.timer_rounded, remainingText, isExpired ? Colors.red : Colors.grey),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoomDetailsScreen(roomId: room['id'])),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C47FF),
                side: const BorderSide(color: Color(0xFF6C47FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('View Room', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
