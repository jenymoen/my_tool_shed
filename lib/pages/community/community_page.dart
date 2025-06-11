import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_tool_shed/pages/community/community_members_page.dart';
import 'package:my_tool_shed/pages/community/community_tools_page.dart';
import 'package:my_tool_shed/pages/community/trust_network_page.dart';
import 'package:my_tool_shed/pages/community/tool_recommendations_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.communityTitle),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(text: l10n.members),
              Tab(text: l10n.tools),
              Tab(text: l10n.trustNetwork),
              Tab(text: l10n.recommendations),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CommunityMembersPage(),
            CommunityToolsPage(),
            TrustNetworkPage(),
            ToolRecommendationsPage(),
          ],
        ),
      ),
    );
  }
}
