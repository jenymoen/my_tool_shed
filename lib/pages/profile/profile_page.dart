import 'package:flutter/material.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/models/community_member.dart';

class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
      ),
      body: StreamBuilder<CommunityMember>(
        stream: communityService.getMemberStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final member = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
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
                          if (member.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              member.email!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Member Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Stats',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          icon: Icons.build,
                          label: 'Tools Shared',
                          value: member.toolsShared.toString(),
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          icon: Icons.handshake,
                          label: 'Tools Borrowed',
                          value: member.toolsBorrowed.toString(),
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          icon: Icons.star,
                          label: 'Rating',
                          value: member.rating.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
