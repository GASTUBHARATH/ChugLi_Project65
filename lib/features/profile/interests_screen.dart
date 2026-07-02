import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/data/services/activity_data_service.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen>
    with SingleTickerProviderStateMixin {
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
    {'emoji': '📚', 'name': 'Study'},
    {'emoji': '📸', 'name': 'Photography'},
    {'emoji': '🚗', 'name': 'Cars'},
  ];

  List<String> _selectedInterests = [];
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _loadInterests();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('selected_interests');
    debugPrint("When loading from Interests screen: $saved");
    debugPrint("Loaded interests: $saved");
    if (saved != null) {
      setState(() {
        _selectedInterests = List<String>.from(saved);
      });
    }
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
        HapticFeedback.lightImpact();
      } else {
        if (_selectedInterests.length < 3) {
          _selectedInterests.add(interest);
          HapticFeedback.mediumImpact();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You can select up to 3 interests."),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF6C47FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleSave() async {
    HapticFeedback.heavyImpact();
    
    debugPrint("Before saving: $_selectedInterests");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_interests', _selectedInterests);
    debugPrint("After saving: $_selectedInterests");
    debugPrint("Saved interests: $_selectedInterests");
    
    ActivityDataService.instance.addActivity(
      title: 'Interests Updated',
      type: 'System',
      action: 'Interests Changed',
      preview: 'Selected: ${_selectedInterests.join(", ")}',
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Interests updated successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
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
          "My Interests",
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Update your interests",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "This helps us show you relevant rooms.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Selected (${_selectedInterests.length}/3)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C47FF),
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _interests.length,
                      itemBuilder: (context, index) {
                        final interest = _interests[index];
                        final name = interest['name']!;
                        final emoji = interest['emoji']!;
                        final isSelected = _selectedInterests.contains(name);

                        return GestureDetector(
                          onTap: () => _toggleInterest(name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6C47FF), Color(0xFF7A5CFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected 
                                      ? const Color(0xFF6C47FF).withValues(alpha: 0.3) 
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: TextStyle(fontSize: 22)),
                                SizedBox(width: 8),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Padding(
              padding: EdgeInsets.all(24.0),
              child: _buildSaveButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        _handleSave();
      },
      onTapCancel: () => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C47FF), Color(0xFF7A5CFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C47FF).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "Save Interests",
              style: TextStyle(
                color: Theme.of(context).cardColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
