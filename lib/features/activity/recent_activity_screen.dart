import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
import 'package:chugli_project65/features/activity/activity_details_screen.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _displayLimit = 20;

  final List<String> _tabs = ['All', 'Rooms', 'Messages', 'Reports', 'System'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF6C47FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Recent Activity",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Color(0xFF6C47FF)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filter options coming soon')));
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Column(
            children: [
              _buildSearchBar(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF6C47FF),
                labelColor: const Color(0xFF6C47FF),
                unselectedLabelColor: Colors.grey,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                onTap: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreRoomService.instance.activitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF)));
            }

            List<Map<String, dynamic>> activities = snapshot.data ?? [];
            List<Map<String, dynamic>> filtered = activities;
            
            // Filter by search query
            if (_searchQuery.isNotEmpty) {
              filtered = filtered.where((a) {
                final title = (a['title'] ?? '').toLowerCase();
                final preview = (a['preview'] ?? '').toLowerCase();
                return title.contains(_searchQuery.toLowerCase()) || preview.contains(_searchQuery.toLowerCase());
              }).toList();
            }

            // Filter by tab
            final currentTab = _tabs[_tabController.index];
            if (currentTab != 'All') {
              final typeFilter = currentTab.substring(0, currentTab.length - 1); // 'Rooms' -> 'Room'
              filtered = filtered.where((a) => a['type'] == typeFilter).toList();
            }

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.3)),
                    SizedBox(height: 16),
                    Text("No activity found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              );
            }

            final limitedList = filtered.take(_displayLimit).toList();

            // Group by date
            Map<String, List<Map<String, dynamic>>> grouped = {};
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(Duration(days: 1));

            for (var activity in limitedList) {
              final dt = activity['timestamp'] as DateTime;
              final date = DateTime(dt.year, dt.month, dt.day);
              
              String groupName;
              if (date == today) {
                groupName = 'Today';
              } else if (date == yesterday) {
                groupName = 'Yesterday';
              } else {
                groupName = DateFormat('MMMM d, yyyy').format(date);
              }

              grouped.putIfAbsent(groupName, () => []).add(activity);
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: grouped.length + (filtered.length > _displayLimit ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == grouped.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _displayLimit += 20;
                          });
                        },
                        child: Text("Load More", style: TextStyle(color: const Color(0xFF6C47FF), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }

                final groupName = grouped.keys.elementAt(index);
                final items = grouped[groupName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Text(
                        groupName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                    ),
                    ...items.map((item) => _buildActivityCard(context, item)).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search activity...',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity) {
    final String type = activity['type'] ?? 'Unknown';
    final String action = activity['action'] ?? '';
    final String title = activity['title'] ?? '';
    final DateTime timestamp = activity['timestamp'] as DateTime;
    final String? preview = activity['preview'];

    IconData icon;
    Color color;
    switch (type) {
      case 'Room':
        icon = Icons.chat_bubble_outline;
        color = const Color(0xFF6C47FF);
        break;
      case 'Message':
        icon = Icons.message_outlined;
        color = const Color(0xFF00C48C);
        break;
      case 'Report':
        icon = Icons.flag_outlined;
        color = Colors.orange;
        break;
      case 'System':
        icon = Icons.settings_outlined;
        color = Colors.grey;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ActivityDetailsScreen(activity: activity)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        action.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('h:mm a').format(timestamp),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preview != null && preview.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      preview,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
