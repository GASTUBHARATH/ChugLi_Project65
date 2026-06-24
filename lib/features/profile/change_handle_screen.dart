import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/core/utils/handle_generator.dart';
import 'package:chugli_project65/data/services/activity_data_service.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';

class ChangeHandleScreen extends StatefulWidget {
  const ChangeHandleScreen({super.key});

  @override
  State<ChangeHandleScreen> createState() => _ChangeHandleScreenState();
}

class _ChangeHandleScreenState extends State<ChangeHandleScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _handleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _currentHandle = 'Loading...';
  String? _selectedSuggestion;
  bool _isLoading = false;

  // Dynamically generated suggestions — refreshable
  List<String> _suggestions = [];

  // Offensive word filter
  static const _blockedWords = ['hate', 'kill', 'sex', 'porn', 'fuck', 'shit', 'ass'];

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _loadCurrentHandle();
    _refreshSuggestions();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCurrentHandle() async {
    try {
      final firestoreHandle =
          await FirestoreRoomService.instance.getUserHandle();
      if (firestoreHandle != null && firestoreHandle.isNotEmpty) {
        if (mounted) setState(() => _currentHandle = firestoreHandle);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userHandle', firestoreHandle);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching handle from Firestore: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('userHandle');
    if (mounted) {
      setState(() => _currentHandle =
          (handle != null && handle.isNotEmpty) ? handle : 'Anonymous User');
    }
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
      _selectedSuggestion = null;
    });
  }

  void _selectSuggestion(String suggestion) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSuggestion = suggestion;
      _handleController.text = HandleGenerator.textOnly(suggestion);
    });
  }

  String? _validateHandle(String? value) {
    if (value == null || value.isEmpty) return 'Handle is required';
    if (value.length < 3) return 'Minimum 3 characters';
    if (value.length > 20) return 'Maximum 20 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Letters, numbers and underscores only';
    }
    if (value == _currentHandle) return 'This is already your handle';
    final lower = value.toLowerCase();
    for (final word in _blockedWords) {
      if (lower.contains(word)) return 'Please choose a more appropriate handle';
    }
    return null;
  }

  void _onHandleUpdate() async {
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a new handle'),
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
      }

      ActivityDataService.instance.addActivity(
        title: 'Handle Changed',
        type: 'System',
        action: 'Handle Updated',
        preview: 'New handle: $handle',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('Handle updated to "$handle"'),
            ],
          ),
          backgroundColor: const Color(0xFF6C47FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF6C47FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Handle',
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Current Handle display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C47FF).withOpacity(0.08),
                        const Color(0xFF7A5CFF).withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF6C47FF).withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Handle',
                        style: TextStyle(
                            color: Color(0xFF6C47FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_rounded,
                              color: Color(0xFF6C47FF), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _currentHandle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Suggestions Section ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pick a new handle',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A)),
                    ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        backgroundColor:
                            const Color(0xFF6C47FF).withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSuggestionsGrid(),
                const SizedBox(height: 24),

                // ── Custom Handle Input ──────────────────────────────
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Or type your own handle',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                ),
                _buildHandleInput(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '3–20 characters · letters, numbers and underscores only · no offensive words',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                _buildUpdateButton(),
                const SizedBox(height: 24),
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
        childAspectRatio: 3.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final isSelected = _selectedSuggestion == suggestion;

        return GestureDetector(
          onTap: () => _selectSuggestion(suggestion),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6C47FF).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF6C47FF) : Colors.grey[200]!,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF6C47FF).withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
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
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        ],
        onChanged: (val) => setState(() => _selectedSuggestion = null),
        validator: _validateHandle,
        decoration: InputDecoration(
          hintText: 'e.g. SilentFox77',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.edit_rounded, color: Color(0xFF6C47FF)),
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
                  builder: (context, value, child) => Text(
                    '${value.text.length}/20',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Update Handle',
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
