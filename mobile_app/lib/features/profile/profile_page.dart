import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../auth/login_page.dart';
import '../../services/gateway_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.client});
  final GatewayClient client;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>> _profile;
  @override
  void initState() {
    super.initState();
    _profile = widget.client.currentUser();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _profile,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final first = data?['firstName']?.toString() ?? '';
      final last = data?['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();
      final email = data?['email']?.toString() ?? '';
      final username = data?['username']?.toString() ?? '';
      final initials =
          '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
              .toUpperCase();
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xff55b0f7),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          initials.isEmpty ? 'AP' : initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              name.isEmpty ? 'Account profile' : name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(username, style: TextStyle(color: AppColors.muted)),
          ),
          Center(
            child: Text(
              email,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 22),
          PageCard(
            child: Column(
              children: [
                AppTile(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () => showComingSoon(context, 'Personal information'),
                ),
                const Divider(height: 1, indent: 62),
                AppTile(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  trailing: const Badge(
                    smallSize: 7,
                    child: Icon(Icons.chevron_right),
                  ),
                  onTap: () => showComingSoon(context, 'Security'),
                ),
                const Divider(height: 1, indent: 62),
                AppTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  onTap: () => showComingSoon(context, 'Notifications'),
                ),
                const Divider(height: 1, indent: 62),
                const AppTile(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'English',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PageCard(
            child: AppTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => showComingSoon(context, 'Help & support'),
            ),
          ),
        ],
      );
    },
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_outline, 'Account Settings', ''),
      (Icons.shield_outlined, 'Security & Privacy', ''),
      (Icons.notifications_none, 'Notifications', ''),
      (Icons.color_lens_outlined, 'Appearance', 'Light'),
      (Icons.language, 'Language', 'English'),
      (Icons.tune, 'Limits & Restrictions', ''),
      (Icons.link, 'Connected Accounts', ''),
      (Icons.info_outline, 'About', ''),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          PageCard(
            child: Column(
              children: items
                  .map(
                    (e) => AppTile(
                      icon: e.$1,
                      title: e.$2,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (e.$3.isNotEmpty)
                            Text(
                              e.$3,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                      onTap: () => showComingSoon(context, e.$2),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          PageCard(
            child: ListTile(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginPage(client: GatewayClient()),
                ),
                (_) => false,
              ),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
