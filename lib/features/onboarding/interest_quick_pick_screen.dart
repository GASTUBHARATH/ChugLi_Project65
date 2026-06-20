import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/features/home/home_feed_screen.dart';

class InterestQuickPickScreen extends StatefulWidget {
  const InterestQuickPickScreen({super.key});

  @override
  State<InterestQuickPickScreen> createState() => _InterestQuickPickScreenState();
}

class _InterestQuickPickScreenState extends State<InterestQuickPickScreen> {
  final List<Map<String, String>> _interests = [
    {'emoji': '🎓', 'name': 'College'},
    {'emoji': '💻', 'name': 'Tech'},
    {'emoji': '🍕', 'name': 'Food'},
    {'emoji': '🎬', 'name': 'Movies'},
    {'emoji': '🎮', 'name': 'Gaming'},
    {'emoji': '✈️', 'name': 'Travel'},
    {'emoji': '🏋️', 'name': 'Fitness'},
    {'emoji': '🎵', 'name': 'Music'},
    {'emoji': '💼', 'name': 'Career'},
  ];

  final Set<String> _selectedInterests = {};

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 3) {
          _selectedInterests.add(interest);
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.vibrate();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Container(
          width: screenWidth * 0.88,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "What kinds of conversations do you love?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Pick up to 3. Skip anytime.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _interests.map((interest) {
                  final name = interest['name']!;
                  final emoji = interest['emoji']!;
                  final isSelected = _selectedInterests.contains(name);
                  return GestureDetector(
                    onTap: () => _toggleInterest(name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF6C47FF), Color(0xFF7A5CFF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF0EDFF),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 14)),
                          SizedBox(width: 4),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        
        debugPrint("Before saving: ${_selectedInterests.toList()}");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('selected_interests', _selectedInterests.toList());
        debugPrint("After saving: ${_selectedInterests.toList()}");
        debugPrint("Saved interests: ${_selectedInterests.toList()}");
        
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeFeedScreen()),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C47FF), Color(0xFF7A5CFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C47FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Start Exploring",
            style: TextStyle(
              color: Theme.of(context).cardColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
