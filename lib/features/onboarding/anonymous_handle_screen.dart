import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/core/utils/handle_generator.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
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
  bool _showCustomInput = false;
  bool _isLoading = false;

  // Dynamically generated suggestions
  List<String> _suggestions = [];

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  // Offensive word filter — basic list, extend as needed
  static const _blockedWords = ['hate', 'kill', 'sex', 'porn', 'fuck', 'shit', 'ass'];

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();

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

  void _refreshSuggestions() {
    HapticFeedback.lightImpact();
    setState(() {
      _suggestions = HandleGenerator.generateHandles(6);
      _selectedHandle = null;
      _handleController.clear();
    });
  }

  void _selectSuggestion(String suggestion) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedHandle = suggestion;
      _showCustomInput = false;
      _handleController.text = HandleGenerator.textOnly(suggestion);
    });
  }

  void _onHandleSubmit() async {
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a handle'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userHandle', handle);

      try {
        await FirestoreRoomService.instance.saveUserProfile(handle: handle);
      } catch (e) {
        debugPrint('Error saving handle to Firestore: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InterestQuickPickScreen()),
      );
    }
  }

  String? _validateHandle(String? value) {
    if (value == null || value.isEmpty) return 'Handle is required';
    if (value.length < 3) return 'Minimum 3 characters';
    if (value.length > 20) return 'Maximum 20 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Letters, numbers and underscores only';
    }
    final lower = value.toLowerCase();
    for (final word in _blockedWords) {
      if (lower.contains(word)) return 'Please choose a more appropriate handle';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Progress row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Color(0xFF6C47FF), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(child: _buildProgressIndicator()),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 30),

                // Title
                const Text(
                  'Choose your\nanonymous handle 😎',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'This is how people nearby will know you.\nYour real identity stays private.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 36),

                // ── Suggestions Section ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pick one for yourself',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    // Generate More button
                    TextButton.icon(
                      onPressed: _refreshSuggestions,
                      icon: const Icon(Icons.refresh_rounded,
                          size: 17, color: Color(0xFF6C47FF)),
                      label: const Text(
                        'Generate More',
                        style: TextStyle(
                          color: Color(0xFF6C47FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: const Color(0xFF6C47FF).withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSuggestionsGrid(),
                const SizedBox(height: 20),

                // ── "Create My Own" Toggle ───────────────────────────────
                _buildCustomHandleToggle(),
                const SizedBox(height: 24),

                // ── Privacy Note ─────────────────────────────────────────
                _buildPrivacyCard(),
                const SizedBox(height: 36),

                // ── Continue Button ──────────────────────────────────────
                _buildContinueButton(),
                const SizedBox(height: 32),
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
        bool active = index <= 2;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active ? const Color(0xFF6C47FF) : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuggestionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final isSelected = _selectedHandle == suggestion;

        return GestureDetector(
          onTap: () => _selectSuggestion(suggestion),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6C47FF).withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF6C47FF) : Colors.grey[200]!,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF6C47FF).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF6C47FF), size: 16),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    suggestion,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6C47FF)
                          : const Color(0xFF1A1A1A),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomHandleToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Create My Own" row toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _showCustomInput = !_showCustomInput;
              if (_showCustomInput) {
                _selectedHandle = null;
                _handleController.clear();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _showCustomInput
                  ? const Color(0xFF6C47FF).withValues(alpha: 0.06)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showCustomInput
                    ? const Color(0xFF6C47FF).withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C47FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Color(0xFF6C47FF), size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create My Own',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '3–20 characters · letters, numbers, underscores',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showCustomInput
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        // Expandable text field
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showCustomInput
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildHandleInput(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHandleInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _handleController,
        maxLength: 20,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        ],
        onChanged: (val) {
          setState(() => _selectedHandle = null);
        },
        validator: _validateHandle,
        decoration: InputDecoration(
          hintText: 'e.g. MysticWolf42',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon:
              const Icon(Icons.person_outline, color: Color(0xFF6C47FF)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          counterText: '',
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: _handleController,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length}/20',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12),
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

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.security_rounded,
                color: Color(0xFF6C47FF), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay anonymous, stay safe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your handle is public. Your identity is always private.',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
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
                color: const Color(0xFF6C47FF).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Text(
                        'Continue',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
