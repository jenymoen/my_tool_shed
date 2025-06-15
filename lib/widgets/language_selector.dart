import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flag/flag.dart';

class LanguageSelector extends StatelessWidget {
  final Function(Locale) onLocaleChanged;

  const LanguageSelector({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: l10n.language,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              const Flag.fromString(
                'US',
                height: 20,
                width: 30,
                borderRadius: 4,
              ),
              const SizedBox(width: 8),
              Text(l10n.english),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('es'),
          child: Row(
            children: [
              const Flag.fromString(
                'ES',
                height: 20,
                width: 30,
                borderRadius: 4,
              ),
              const SizedBox(width: 8),
              Text(l10n.spanish),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('fr'),
          child: Row(
            children: [
              const Flag.fromString(
                'FR',
                height: 20,
                width: 30,
                borderRadius: 4,
              ),
              const SizedBox(width: 8),
              Text(l10n.french),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('no'),
          child: Row(
            children: [
              const Flag.fromString(
                'NO',
                height: 20,
                width: 30,
                borderRadius: 4,
              ),
              const SizedBox(width: 8),
              Text(l10n.norwegian),
            ],
          ),
        ),
      ],
      onSelected: onLocaleChanged,
    );
  }
}
