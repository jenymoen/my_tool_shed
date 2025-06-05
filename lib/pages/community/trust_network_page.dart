import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/member_card.dart';
import 'package:my_tool_shed/pages/community/member_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrustNetworkPage extends StatelessWidget {
  const TrustNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Trusted Members'),
              Tab(text: 'Trusted By'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TrustedMembersTab(
                  communityService: communityService,
                  currentUserId: currentUserId,
                ),
                _TrustedByTab(
                  communityService: communityService,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustedMembersTab extends StatelessWidget {
  final CommunityService communityService;
  final String currentUserId;

  const _TrustedMembersTab({
    required this.communityService,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityMember>>(
      stream: communityService.getCommunityMembers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final members = snapshot.data!
            .where((member) => member.trustedBy.contains(currentUserId))
            .toList();

        if (members.isEmpty) {
          return const Center(
            child: Text('No trusted members yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return MemberCard(
              member: member,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberProfilePage(
                      member: member,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TrustedByTab extends StatelessWidget {
  final CommunityService communityService;
  final String currentUserId;

  const _TrustedByTab({
    required this.communityService,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityMember>>(
      stream: communityService.getCommunityMembers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final members = snapshot.data!
            .where((member) => member.trustedUsers.contains(currentUserId))
            .toList();

        if (members.isEmpty) {
          return const Center(
            child: Text('No members trust you yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return MemberCard(
              member: member,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberProfilePage(
                      member: member,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
