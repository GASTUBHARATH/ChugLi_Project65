import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_data_service.dart';

class ChangeHandleScreen extends StatefulWidget {
  const ChangeHandleScreen({super.key});

  @override
  State<ChangeHandleScreen> createState() => _ChangeHandleScreenState();
}

class _ChangeHandleScreenState extends State<ChangeHandleScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _handleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _currentHandle = "Loading...";
  String? _selectedHandle;

  final List<String> _suggestions = [
    "NeonTiger44 🐯",
    "SleepyMango42 🥭",
    "CryptoPanda99 🐼",
    "ZenCactus13 🌵",
  ];

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _loadCurrentHandle();
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCurrentHandle() async {
    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('userHandle');
    if (handle != null && handle.isNotEmpty) {
      setState(() {
        _currentHandle = handle;
      });
    } else {
      setState(() {
        _currentHandle = "Anonymous User";
      });
    }
  }

  @override
  void dispose() {
    _handleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onHandleUpdate() async {
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose a new handle"),
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

      ActivityDataService.instance.addActivity(
        title: 'Handle Changed',
        type: 'System',
        action: 'Handle Updated',
        preview: 'New handle: $handle',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Handle updated successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
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
          "Change Handle",
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Current Handle
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C47FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Current Handle",
                        style: TextStyle(
                          color: Color(0xFF6C47FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _currentHandle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Handle Input
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      "Enter your new anonymous handle",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _buildHandleInput(),
                
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You can only change your handle once every 24 hours.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
                SizedBox(height: 40),

                // Update Button
                _buildUpdateButton(),
              ],
            ),
          ),
        ),
      ),
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
            _selectedHandle = null;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) return "Handle is required";
          if (value.length < 3) return "Minimum 3 characters";
          if (value == _currentHandle) return "This is already your handle";
          return null;
        },
        decoration: InputDecoration(
          hintText: "e.g. NeonTiger44",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.edit, color: Color(0xFF6C47FF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          counterText: "",
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

  Widget _buildUpdateButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        _onHandleUpdate();
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
          child: Center(
            child: Text(
              "Update Handle",
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
