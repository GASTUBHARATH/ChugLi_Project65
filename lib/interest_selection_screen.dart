import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen>
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

  final List<String> _selectedInterests = [];
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
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
        if (_selectedInterests.length < 6) {
          _selectedInterests.add(interest);
          HapticFeedback.mediumImpact();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You can select up to 6 interests."),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF6C47FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    });
  }

  void _handleContinue() {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Select at least 3 interests to continue."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      // Navigate to HomeFeedScreen()
      debugPrint("Interests selected: $_selectedInterests");
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeFeedScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Back Button & Progress
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF6C47FF), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(child: _buildProgressIndicator()),
                  SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "What kinds of conversations\ndo you love?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Pick at least 3. You can choose up to 6.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Selected: ${_selectedInterests.length} / 6",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedInterests.length >= 3 
                            ? const Color(0xFF6C47FF) 
                            : Colors.grey,
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

                        return _InterestCard(
                          name: name,
                          emoji: emoji,
                          isSelected: isSelected,
                          onTap: () => _toggleInterest(name),
                        );
                      },
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Continue Button
            Padding(
              padding: EdgeInsets.all(24.0),
              child: _buildContinueButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        bool completed = index < 3;
        bool active = index == 3;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: (completed || active) ? const Color(0xFF6C47FF) : const Color(0xFFE5E5E5),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton() {
    bool isEnabled = _selectedInterests.length >= 3;
    return GestureDetector(
      onTapDown: isEnabled ? (_) => _buttonController.forward() : null,
      onTapUp: isEnabled ? (_) {
        _buttonController.reverse();
        _handleContinue();
      } : null,
      onTapCancel: isEnabled ? () => _buttonController.reverse() : null,
      child: ScaleTransition(
        scale: _buttonScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: isEnabled 
                ? const LinearGradient(
                    colors: [Color(0xFF6C47FF), Color(0xFF7A5CFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isEnabled ? null : Colors.grey[400],
            boxShadow: isEnabled ? [
              BoxShadow(
                color: const Color(0xFF6C47FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              "Start Exploring",
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

class _InterestCard extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestCard({
    required this.name,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF6C47FF).withOpacity(0.3) 
                  : Colors.black.withOpacity(0.03),
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
  }
}
