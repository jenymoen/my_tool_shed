import 'package:flutter/material.dart';
import 'package:my_tool_shed/pages/community/community_members_page.dart';
import 'package:my_tool_shed/pages/community/community_tools_page.dart';
import 'package:my_tool_shed/pages/community/trust_network_page.dart';
import 'package:my_tool_shed/pages/community/tool_recommendations_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Tools'),
            Tab(text: 'Trust Network'),
            Tab(text: 'Recommendations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CommunityMembersPage(),
          CommunityToolsPage(),
          TrustNetworkPage(),
          ToolRecommendationsPage(),
        ],
      ),
    );
  }
}
