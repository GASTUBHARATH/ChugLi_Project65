import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/features/info/community_guidelines_screen.dart';
import 'package:chugli_project65/features/reports/reports_history_screen.dart';
import 'package:chugli_project65/features/info/privacy_detail_screen.dart';
import 'package:chugli_project65/features/info/help_support_screen.dart';

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF6C47FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Privacy & Safety",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Banner ────────────────────────────────────────
              _buildHeroBanner(context),
              const SizedBox(height: 28),

              // ── Section 1: Privacy ─────────────────────────────────
              _buildSectionTitle("Privacy"),
              _buildSettingsCard(context, children: [
                _buildActionTile(context, "Anonymous Profiles", Icons.person_outline_rounded, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "Anonymous Profiles",
                    content: "ChugLi is built around anonymity. No real names are required — your identity is protected at all times.\n\nWe never ask for your email, phone number, or any personal information. You interact through anonymous handles that you can change anytime.\n\nYour conversations, reactions, and activity are never linked to your real identity. We believe in giving you the freedom to express yourself without judgment.",
                  )));
                }),
                _buildDivider(),
                _buildActionTile(context, "Location Privacy", Icons.location_on_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "Location Privacy",
                    content: "Location is used only for nearby room discovery — so you can find conversations happening around you.\n\nYou have full control over your radius settings and can adjust how far you want to discover rooms.\n\nWe do not store historical location data. Your location is processed dynamically and is never shared with other users or third parties.",
                  )));
                }),
                _buildDivider(),
                _buildActionTile(context, "Data & Deletion", Icons.delete_outline_rounded, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "Data & Deletion",
                    content: "You can delete your account at any time from Settings. When you do, all your data is permanently removed.\n\nMessages are automatically wiped from our servers the moment a room expires. Your device may cache messages locally while the app is running, but nothing is kept permanently.\n\nYour data is handled securely and is never sold to third parties. Your privacy is our priority.",
                  )));
                }),
              ]),
              const SizedBox(height: 24),

              // ── Section 2: Safety Features ─────────────────────────
              _buildSectionTitle("Safety Features"),
              _buildSettingsCard(context, children: [
                _buildActionTile(context, "User Reporting System", Icons.flag_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "User Reporting System",
                    content: "If you encounter inappropriate behavior, you can report it directly using in-app tools.\n\nLong-press any message in a chat room to access the report option. Provide a reason and our moderation system will review the report.\n\nAll reports are taken seriously and acted upon to maintain a safe environment for everyone.",
                  )));
                }),
                _buildDivider(),
                _buildActionTile(context, "Community Moderation", Icons.shield_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "Community Moderation",
                    content: "ChugLi has built-in community moderation to keep conversations safe.\n\nAuto-ban protection automatically removes users who receive reports from more than 50% of participants in a room.\n\nRoom creators have moderation controls including the ability to pin messages and end rooms early. This distributed approach ensures that the community helps maintain standards.",
                  )));
                }),
                _buildDivider(),
                _buildActionTile(context, "Screenshot Protection", Icons.no_photography_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "Screenshot Protection",
                    content: "Chat rooms in ChugLi have screenshot protection enabled to help keep conversations private.\n\nThis feature discourages screen capture within active conversations, adding an extra layer of privacy for all participants.\n\nWhile no technical measure is 100% foolproof, this protection serves as a strong deterrent and a signal that privacy is valued in our community.",
                  )));
                }),
                _buildDivider(),
                _buildActionTile(context, "Muted Rooms", Icons.volume_off_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                    title: "Muted Rooms",
                    content: "You can mute any room you don't want to see in your feed.\n\nMuted rooms are hidden from your home feed and won't send you any notifications. You can manage your muted rooms list from the Settings screen.\n\nThis gives you full control over your experience — see only the conversations that matter to you.",
                  )));
                }),
              ]),
              const SizedBox(height: 24),

              // ── Section 3: Community Guidelines ────────────────────
              _buildSectionTitle("Community Guidelines"),
              _buildSettingsCard(context, children: [
                _buildActionTile(context, "View Full Guidelines", Icons.menu_book_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityGuidelinesScreen()));
                }),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildBulletItem(context, Icons.people_rounded, "Be respectful to others"),
                    const SizedBox(height: 12),
                    _buildBulletItem(context, Icons.block_rounded, "No harassment or bullying"),
                    const SizedBox(height: 12),
                    _buildBulletItem(context, Icons.gavel_rounded, "No hate speech or threats"),
                    const SizedBox(height: 12),
                    _buildBulletItem(context, Icons.masks_rounded, "No illegal activities or impersonation"),
                    const SizedBox(height: 12),
                    _buildBulletItem(context, Icons.report_gmailerrorred_rounded, "No spam or misleading content"),
                    const SizedBox(height: 12),
                    _buildBulletItem(context, Icons.flag_rounded, "Report inappropriate behavior"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 4: Child Safety ────────────────────────────
              _buildSectionTitle("Child Safety"),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildBulletItem(context, Icons.cake_outlined, "Users should be at least 13 years old"),
                    const SizedBox(height: 14),
                    _buildBulletItem(context, Icons.shield_rounded, "No grooming or exploitation"),
                    const SizedBox(height: 14),
                    _buildBulletItem(context, Icons.warning_amber_rounded, "Harmful behavior will not be tolerated"),
                    const SizedBox(height: 14),
                    _buildBulletItem(context, Icons.remove_circle_outline, "Serious violations may result in restrictions or removal"),
                    const SizedBox(height: 14),
                    _buildBulletItem(context, Icons.flag_outlined, "Report harmful behavior immediately"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 5: Contact & Support ───────────────────────
              _buildSectionTitle("Contact & Support"),
              _buildSettingsCard(context, children: [
                _buildActionTile(context, "Report Issues", Icons.bug_report_outlined, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHistoryScreen()));
                }),
                _buildDivider(),
                _buildActionTile(context, "Help & Support", Icons.help_outline_rounded, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                }),
                _buildDivider(),
                _buildActionTile(context, "Privacy Policy", Icons.description_outlined, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Coming Soon'),
                      backgroundColor: const Color(0xFF6C47FF),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }),
                _buildDivider(),
                _buildActionTile(context, "Terms of Service", Icons.article_outlined, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Coming Soon'),
                      backgroundColor: const Color(0xFF6C47FF),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 32),

              // ── Footer Banner ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C47FF).withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text(
                    'Your privacy is our priority.\nWe never sell your data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6C47FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Banner ──────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFFB39DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C47FF).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy & Safety Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your safety matters. Learn how ChugLi protects you.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ── Settings Card ────────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // ── Action Tile ──────────────────────────────────────────────────
  Widget _buildActionTile(BuildContext context, String title, IconData icon, {Color? color, VoidCallback? onTap}) {
    final useColor = color ?? const Color(0xFF6C47FF);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: useColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: useColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // ── Bullet Item ──────────────────────────────────────────────────
  Widget _buildBulletItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6C47FF), size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Divider ──────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 60,
      endIndent: 20,
    );
  }
}
