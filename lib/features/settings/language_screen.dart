import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/features/settings/language_updated_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';
  String _filterPreference = 'Show all languages';
  bool _autoDetect = true;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Marathi'
  ];

  final List<String> _filters = [
    'Show all languages',
    'Prefer my language',
    'Only my language'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('pref_language') ?? 'English';
      _filterPreference = prefs.getString('pref_lang_filter') ?? 'Show all languages';
      _autoDetect = prefs.getBool('pref_lang_autodetect') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', _selectedLanguage);
    await prefs.setString('pref_lang_filter', _filterPreference);
    await prefs.setBool('pref_lang_autodetect', _autoDetect);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LanguageUpdatedScreen()),
      );
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
          "Language",
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("App Language"),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile("Auto-detect device language", _autoDetect, (val) {
                      setState(() => _autoDetect = val);
                    }),
                    if (!_autoDetect) ...[
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      ..._languages.map((lang) => _buildRadioTile(
                            title: lang,
                            value: lang,
                            groupValue: _selectedLanguage,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLanguage = val);
                            },
                          )).toList(),
                    ]
                  ],
                ),
              ),
              SizedBox(height: 24),

              _buildSectionTitle("Content Preferences"),
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "Choose what languages you see in rooms and feeds.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: _filters.map((filter) => _buildRadioTile(
                        title: filter,
                        value: filter,
                        groupValue: _filterPreference,
                        onChanged: (val) {
                          if (val != null) setState(() => _filterPreference = val);
                        },
                      )).toList(),
                ),
              ),
              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _saveSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: const Color(0xFF6C47FF).withOpacity(0.5),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF6C47FF),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.grey[400],
      ),
      child: RadioListTile<String>(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: value == groupValue ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        value: value,
        groupValue: groupValue,
        activeColor: const Color(0xFF6C47FF),
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
