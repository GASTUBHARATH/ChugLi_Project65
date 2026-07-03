import 'package:flutter/material.dart';
import 'package:chugli_project65/data/services/mute_service.dart';

class MutedRoomsScreen extends StatefulWidget {
  const MutedRoomsScreen({super.key});

  @override
  State<MutedRoomsScreen> createState() => _MutedRoomsScreenState();
}

class _MutedRoomsScreenState extends State<MutedRoomsScreen> {
  List<Map<String, dynamic>> _mutedRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMutedRooms();
  }

  Future<void> _loadMutedRooms() async {
    setState(() => _isLoading = true);
    final rooms = await MuteService.instance.getMutedRooms();
    if (mounted) {
      setState(() {
        _mutedRooms = rooms;
        _isLoading = false;
      });
    }
  }

  Future<void> _unmuteRoom(String id) async {
    await MuteService.instance.unmuteRoom(id);
    _loadMutedRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muted Rooms'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF)))
          : _mutedRooms.isEmpty
              ? const Center(
                  child: Text(
                    'No muted rooms.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mutedRooms.length,
                  itemBuilder: (context, index) {
                    final room = _mutedRooms[index];
                    final date = DateTime.tryParse(room['mutedAt'] ?? '');
                    final dateStr = date != null 
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Unknown date';
                        
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          room['title'] ?? 'Unknown Room',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Category: ${room['category']} • Muted: $dateStr'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up, color: Color(0xFF6C47FF)),
                          tooltip: 'Unmute',
                          onPressed: () => _unmuteRoom(room['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
