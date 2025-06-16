import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_tool_shed/pages/community/community_members_page.dart';
import 'package:my_tool_shed/pages/community/community_tools_page.dart';
import 'package:my_tool_shed/pages/community/trust_network_page.dart';
import 'package:my_tool_shed/pages/community/tool_recommendations_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityTitle),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.members),
            Tab(text: l10n.tools),
            Tab(text: l10n.trustNetwork),
            Tab(text: l10n.recommendations),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunityMembersPage(
            currentUserId: _currentUserId,
          ),
          const CommunityToolsPage(),
          const TrustNetworkPage(),
          const ToolRecommendationsPage(),
        ],
      ),
    );
  }
}
