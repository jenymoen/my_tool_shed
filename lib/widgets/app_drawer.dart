import 'package:flutter/material.dart';
import 'package:my_tool_shed/pages/dashboard_page.dart';
import 'package:my_tool_shed/pages/login_page.dart';
import 'package:my_tool_shed/pages/profile_page.dart';
import 'package:my_tool_shed/pages/settings_page.dart';
import 'package:my_tool_shed/pages/tools_page.dart';
import 'package:my_tool_shed/services/auth_service.dart';
import 'package:my_tool_shed/pages/community/community_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  final Function(Locale) onLocaleChanged;

  const AppDrawer({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    return Drawer(
      child: Column(
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text("User Name"), // Replace with actual user name
            accountEmail:
                Text("user@example.com"), // Replace with actual user email
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "U", // Replace with first letter of user's name
                style: TextStyle(fontSize: 40.0),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n.dashboard),
            onTap: () {
              navigator.pop();
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    onLocaleChanged: onLocaleChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: Text(l10n.allTools),
            onTap: () {
              navigator.pop();
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ToolsPage(
                    onLocaleChanged: onLocaleChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(l10n.community),
            onTap: () {
              navigator.pop();
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const CommunityPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            onTap: () {
              navigator.pop();
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () {
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onLocaleChanged: onLocaleChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
            onTap: () {
              Navigator.of(context).pop();
              AuthService().signOut().then((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
