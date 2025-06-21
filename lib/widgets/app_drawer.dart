import 'package:flutter/material.dart';
import 'package:my_tool_shed/pages/dashboard_page.dart';
import 'package:my_tool_shed/pages/login_page.dart';
import 'package:my_tool_shed/pages/profile_page.dart';
import 'package:my_tool_shed/pages/settings_page.dart';
import 'package:my_tool_shed/pages/tools_page.dart';
import 'package:my_tool_shed/services/auth_service.dart';
import 'package:my_tool_shed/pages/community/community_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatefulWidget {
  final Function(Locale) onLocaleChanged;

  const AppDrawer({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  String _getUserDisplayName() {
    if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    return _currentUser?.email?.split('@').first ?? 'User';
  }

  String _getUserEmail() {
    return _currentUser?.email ?? 'No email available';
  }

  String _getUserInitial() {
    final displayName = _getUserDisplayName();
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        _currentUser = snapshot.data;

        return Drawer(
          child: Column(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(_getUserDisplayName()),
                accountEmail: Text(_getUserEmail()),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    _getUserInitial(),
                    style: const TextStyle(fontSize: 40.0),
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
                        onLocaleChanged: widget.onLocaleChanged,
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
                        onLocaleChanged: widget.onLocaleChanged,
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
                      builder: (context) => CommunityPage(
                          onLocaleChanged: widget.onLocaleChanged),
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
                      builder: (context) =>
                          ProfilePage(onLocaleChanged: widget.onLocaleChanged),
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
                        onLocaleChanged: widget.onLocaleChanged,
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
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
