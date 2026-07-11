import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _showTicketForm = false;

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
        title: const Text(
          "Help & Support",
          style: TextStyle(
              color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQCard(
                context,
                "How do I change my handle?",
                "You can change your handle once every 24 hours in Settings > Change Handle, or tap 'Change Handle' from the drawer menu on the home screen.",
              ),
              const SizedBox(height: 16),
              _buildFAQCard(
                context,
                "Why did my room disappear?",
                "Rooms automatically expire based on the time limit set by the creator. Once a room expires, it can no longer be accessed. You can view your past rooms under My Rooms in the drawer.",
              ),
              const SizedBox(height: 16),
              _buildFAQCard(
                context,
                "Is Bolbro truly anonymous?",
                "Yes. We do not require real names or profile pictures. Your handle is auto-generated and randomly changed on request. We do not store chat histories after rooms expire.",
              ),
              const SizedBox(height: 16),
              _buildFAQCard(
                context,
                "How do I report someone?",
                "Tap the flag icon inside any room or go to Settings > Report a Problem. Our moderation team reviews all reports within 24 hours.",
              ),
              const SizedBox(height: 16),
              _buildFAQCard(
                context,
                "How does the radius work?",
                "Bolbro uses your approximate GPS location to show you rooms within your chosen radius (0.5 km – 5 km). Your exact location is never shared with other users.",
              ),
              const SizedBox(height: 16),
              _buildFAQCard(
                context,
                "Can I delete my account?",
                "Yes. Go to Settings > Delete Account. This will permanently remove all your data from our servers. This action cannot be undone.",
              ),
              const SizedBox(height: 32),

              // ── Contact / Ticket Section ─────────────────────────
              const Text(
                "Contact Support",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showTicketForm
                    ? _TicketForm(
                        key: const ValueKey('form'),
                        onCancel: () =>
                            setState(() => _showTicketForm = false),
                        onSubmitted: () =>
                            setState(() => _showTicketForm = false),
                      )
                    : _buildContactCard(context),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      key: const ValueKey('card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_outlined,
              color: Color(0xFF6C47FF), size: 44),
          const SizedBox(height: 12),
          const Text(
            "Still need help?",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          const Text(
            "Submit a support ticket and our team will get back to you within 24 hours.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showTicketForm = true),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Submit a Ticket',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C47FF),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(
      BuildContext context, String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF6C47FF),
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                fontSize: 15),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ticket Submission Form ─────────────────────────────────────────────────
class _TicketForm extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSubmitted;

  const _TicketForm({
    super.key,
    required this.onCancel,
    required this.onSubmitted,
  });

  @override
  State<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<_TicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Bug Report',
    'Account Issue',
    'Privacy Concern',
    'Content Report',
    'Feature Request',
    'Other',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final userHandle = prefs.getString('userHandle') ?? 'Anonymous';

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userUid': user?.uid ?? 'anonymous',
        'userHandle': userHandle,
        'userEmail': _emailCtrl.text.trim().isEmpty
            ? 'Not provided'
            : _emailCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ticket submitted! Our team will get back to you soon.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF00C48C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF6C47FF).withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C47FF).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: Color(0xFF6C47FF), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'New Support Ticket',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            const Text('Category',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _inputDecoration('Select a category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
            const SizedBox(height: 16),

            // Subject
            const Text('Subject',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _subjectCtrl,
              decoration: _inputDecoration('Brief description of your issue'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                if (v.trim().length < 5) {
                  return 'Subject must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _inputDecoration(
                  'Describe the issue in detail. Include any error messages, steps to reproduce, or relevant information.'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe the issue';
                }
                if (v.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (optional)
            const Text('Contact Email (optional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                  'your@email.com — so we can follow up with you'),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final emailRegex =
                      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit / Cancel Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C47FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Ticket',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.06),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C47FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
