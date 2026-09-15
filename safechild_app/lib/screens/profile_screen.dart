import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/localization_service.dart';
import '../services/theme_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref, AppTranslations tr) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr.translate('logout_confirm_title')),
        content: Text(tr.translate('logout_confirm_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(tr.translate('sign_out').toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final tr = AppTranslations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Profil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue[50],
                    backgroundImage: const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {}, // Future profile photo update
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue[900],
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              user?.name ?? (tr.translate('role') == 'Rôle' ? 'Utilisateur' : 'User'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? "email@example.com",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // Theme Toggle
            _buildActionCard(
              context,
              child: SwitchListTile(
                title: Text(tr.translate('dark_mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
                secondary: Icon(
                  themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.blue[900],
                ),
                value: themeMode == ThemeMode.dark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme(val);
                },
              ),
            ),

            const SizedBox(height: 15),

            // Language Toggle
            _buildActionCard(
              context,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: Colors.blue[900]),
                        const SizedBox(width: 16),
                        Text(tr.translate('language'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: locale.languageCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text("Français")),
                        DropdownMenuItem(value: 'en', child: Text("English")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(localeProvider.notifier).setLocale(Locale(val));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Stats de l'utilisateur
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat(tr.translate('reports_title'), "3"),
                  _buildMiniStat("Points", "120"),
                  _buildMiniStat(tr.translate('found'), "1"),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Menu options
            _buildMenuItem(context, Icons.person_outline, tr.translate('profile_info')),
            _buildMenuItem(context, Icons.notifications_outlined, tr.translate('notif_prefs')),
            _buildMenuItem(context, Icons.security_outlined, tr.translate('security_privacy')),
            _buildMenuItem(context, Icons.help_outline, tr.translate('help_center')),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(),
            ),
            
            // Bouton Déconnexion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                onTap: () => _showLogoutDialog(context, ref, tr),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red),
                ),
                title: Text(
                  tr.translate('sign_out'),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: child,
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white10 
              : Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue[900]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
