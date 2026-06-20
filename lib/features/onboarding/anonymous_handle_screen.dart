import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/features/onboarding/interest_quick_pick_screen.dart';

class AnonymousHandleScreen extends StatefulWidget {
  const AnonymousHandleScreen({super.key});

  @override
  State<AnonymousHandleScreen> createState() => _AnonymousHandleScreenState();
}

class _AnonymousHandleScreenState extends State<AnonymousHandleScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _handleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedHandle;

  final List<String> _suggestions = [
    "SleepyMango42 🥭",
    "CosmicDosa99 🌯",
    "ChaoticPigeon07 🐦",
    "BoldIdli88 🍚",
    "MidnightSamosa55 🥟",
    "ZenCactus13 🌵",
    "GlitchyOtter31 🦦",
    "NachtfalterXL 🦋",
  ];

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
    _handleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onHandleSubmit() async {
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose a handle"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userHandle', handle);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const InterestQuickPickScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                // Top Section: Back Arrow & Progress
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Color(0xFF6C47FF), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(child: _buildProgressIndicator()),
                    SizedBox(width: 40), // Balance the back arrow
                  ],
                ),
                SizedBox(height: 30),

                // Title Section
                Text(
                  "Choose your\nanonymous handle 😎",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "This is how people nearby will know you.\nYour real identity stays private.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 40),

                // Handle Input
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      "Enter your anonymous handle",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _buildHandleInput(),
                SizedBox(height: 30),

                // Suggestions Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                    child: Text(
                      "Suggestions for you",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
                _buildSuggestionsGrid(),
                SizedBox(height: 30),

                // Privacy Card
                _buildPrivacyCard(),
                SizedBox(height: 40),

                // Continue Button
                _buildContinueButton(),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        bool completed = index < 2;
        bool active = index == 2;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: (completed || active) ? const Color(0xFF6C47FF) : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHandleInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _handleController,
        maxLength: 20,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        onChanged: (val) {
          setState(() {
            _selectedHandle = null; // Clear suggestion selection if typing
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) return "Handle is required";
          if (value.length < 3) return "Minimum 3 characters";
          return null;
        },
        decoration: InputDecoration(
          hintText: "e.g. SleepyMango42",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF6C47FF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          counterText: "", // Hidden because custom counter is not requested
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: _handleController,
                  builder: (context, value, child) {
                    return Text(
                      "${value.text.length}/20",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final isSelected = _selectedHandle == suggestion;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedHandle = suggestion;
              // Strip emoji for the input field
              _handleController.text = suggestion.split(' ')[0];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C47FF).withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF6C47FF) : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                suggestion,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6C47FF) : const Color(0xFF1A1A1A),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.security, color: Color(0xFF6C47FF)),
          ),
          SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stay anonymous, stay safe",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your handle is public, but your identity is always private.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        _onHandleSubmit();
      },
      onTapCancel: () => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: Container(
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
                color: const Color(0xFF6C47FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Text(
                  "Continue",
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
