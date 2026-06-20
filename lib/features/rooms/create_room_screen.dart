import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/data/services/room_data_service.dart';
import 'dart:math';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _selectedExpiry = '2h';
  String _selectedParticipants = '50';
  String _selectedVisibility = 'Public';

  final List<Map<String, String>> _categories = [
    {'emoji': '❓', 'label': 'Question'},
    {'emoji': '🆘', 'label': 'Help'},
    {'emoji': '😂', 'label': 'Funny'},
    {'emoji': '🎤', 'label': 'Confession'},
    {'emoji': '🍕', 'label': 'Food'},
    {'emoji': '🤝', 'label': 'Networking'},
    {'emoji': '🎓', 'label': 'College'},
  ];

  final List<String> _expiryOptions = ['30m', '2h', '6h', '24h'];
  final List<String> _participantOptions = ['5', '20', '50', '100', 'Unlimited'];
  final List<String> _visibilityOptions = ['Public', 'Invite Only'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createRoom() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room title is required'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Duration expiryDuration;
    switch (_selectedExpiry) {
      case '30m': expiryDuration = const Duration(minutes: 30); break;
      case '6h': expiryDuration = const Duration(hours: 6); break;
      case '24h': expiryDuration = const Duration(hours: 24); break;
      case '2h':
      default: expiryDuration = const Duration(hours: 2); break;
    }

    final newRoom = {
      'id': DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
      'title': _titleController.text.trim(),
      'category': _selectedCategory!,
      'description': _descriptionController.text.trim(),
      'preview': 'Room created! Start the conversation...',
      'expiryTime': expiryDuration,
      'createdAt': DateTime.now(),
      'participants': 1, // Only the creator initially
      'maxParticipants': _selectedParticipants,
      'visibility': _selectedVisibility,
      'isHighActivity': false,
      'createdBy': 'current_user',
      'joinedUsers': <String>['current_user'],
      'reactions': <String>[],
      'messages': <Map<String, dynamic>>[],
    };

    RoomDataService.instance.addRoom(newRoom);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Room',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Title
            Text(
              'Room Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'What do you want to talk about?',
                hintStyle: TextStyle(color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                counterStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Category Grid
            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat['label']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C47FF).withOpacity(0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C47FF)
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat['emoji']!, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF6C47FF)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 28),

            // Optional Description
            Text(
              'Optional Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLength: 150,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add more details about your room...',
                hintStyle: TextStyle(color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                counterStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Expiry Options
            Text(
              'Expiry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _expiryOptions.map((opt) {
                  final isSelected = _selectedExpiry == opt;
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedExpiry = opt);
                        }
                      },
                      selectedColor: const Color(0xFF6C47FF),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 28),

            // Max Participants
            Text(
              'Max Participants',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _participantOptions.map((opt) {
                final isSelected = _selectedParticipants == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedParticipants = opt);
                    }
                  },
                  selectedColor: const Color(0xFF6C47FF),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 28),

            // Visibility
            Text(
              'Visibility',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                children: _visibilityOptions.map((opt) {
                  final isSelected = _selectedVisibility == opt;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedVisibility = opt);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          opt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : Colors.black54,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 40),

            // Create Room Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFF7B61FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C47FF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Create Room',
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
