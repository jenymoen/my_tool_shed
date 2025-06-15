import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_tool_shed/widgets/language_selector.dart';

class SettingsPage extends StatelessWidget {
  final Function(Locale) onLocaleChanged;

  const SettingsPage({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: LanguageSelector(onLocaleChanged: onLocaleChanged),
          ),
          const Divider(),
          // Add more settings here as needed
        ],
      ),
    );
  }
}
