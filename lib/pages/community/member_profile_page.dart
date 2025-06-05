import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/tool_card.dart';
import 'package:my_tool_shed/pages/community/tool_details_page.dart';

class MemberProfilePage extends StatelessWidget {
  final CommunityMember member;
  final String currentUserId;

  const MemberProfilePage({
    super.key,
    required this.member,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();
    final isCurrentUser = member.id == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        actions: [
          if (!isCurrentUser)
            IconButton(
              icon: Icon(
                member.trustedBy.contains(currentUserId)
                    ? Icons.verified
                    : Icons.verified_outlined,
              ),
              onPressed: () {
                if (member.trustedBy.contains(currentUserId)) {
                  communityService.removeTrust(currentUserId, member.id);
                } else {
                  communityService.addTrust(currentUserId, member.id);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: member.photoUrl != null
                      ? NetworkImage(member.photoUrl!)
                      : null,
                  child: member.photoUrl == null
                      ? Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            ' (${member.totalRatings} ratings)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Member Info
            if (member.address != null) ...[
              _InfoRow(
                icon: Icons.location_on,
                title: 'Address',
                content: member.address!,
              ),
              const SizedBox(height: 16),
            ],
            if (member.phone != null) ...[
              _InfoRow(
                icon: Icons.phone,
                title: 'Phone',
                content: member.phone!,
              ),
              const SizedBox(height: 16),
            ],
            if (member.bio != null) ...[
              _InfoRow(
                icon: Icons.info,
                title: 'About',
                content: member.bio!,
              ),
              const SizedBox(height: 16),
            ],
            _InfoRow(
              icon: Icons.people,
              title: 'Trust Network',
              content:
                  'Trusted by ${member.trustedBy.length} members • Trusts ${member.trustedUsers.length} members',
            ),
            const SizedBox(height: 24),

            // Member's Tools
            Text(
              'Available Tools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Tool>>(
              stream: communityService.getCommunityTools(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final tools = snapshot.data!
                    .where((tool) => tool.ownerId == member.id)
                    .toList();

                if (tools.isEmpty) {
                  return const Text('No tools available for borrowing');
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return ToolCard(
                      tool: tool,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ToolDetailsPage(
                              tool: tool,
                              currentUserId: currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
