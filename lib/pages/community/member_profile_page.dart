import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/tool_card.dart';
import 'package:my_tool_shed/pages/community/tool_details_page.dart';

class MemberProfilePage extends StatefulWidget {
  final CommunityMember member;
  final String currentUserId;

  const MemberProfilePage({
    super.key,
    required this.member,
    required this.currentUserId,
  });

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  void _showEditMemberDialog(BuildContext context) {
    if (!mounted) return;

    final nameController = TextEditingController(text: widget.member.name);
    final emailController =
        TextEditingController(text: widget.member.email ?? '');
    final phoneController =
        TextEditingController(text: widget.member.phone ?? '');
    final addressController =
        TextEditingController(text: widget.member.address ?? '');
    final bioController = TextEditingController(text: widget.member.bio ?? '');
    final communityService = CommunityService();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter your phone number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter your address',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (!mounted) return;

                final name = nameController.text.trim();
                if (name.isEmpty) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                try {
                  final updatedMember = widget.member.copyWith(
                    name: name,
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    bio: bioController.text.trim().isEmpty
                        ? null
                        : bioController.text.trim(),
                  );

                  await communityService.updateCommunityMember(updatedMember);

                  if (!mounted) return;
                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();
    final isCurrentUser = widget.member.id == widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
        actions: [
          if (widget.currentUserId == widget.member.id)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditMemberDialog(context),
            ),
          if (!isCurrentUser)
            StreamBuilder<CommunityMember>(
              stream: communityService.getMemberStream(widget.member.id),
              builder: (context, snapshot) {
                final isTrusted =
                    snapshot.data?.trustedBy.contains(widget.currentUserId) ??
                        false;
                return IconButton(
                  icon: Icon(
                    isTrusted ? Icons.verified : Icons.verified_outlined,
                    color: Colors.white,
                    size: isTrusted ? 28 : 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isTrusted ? Colors.white.withAlpha(51) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      if (isTrusted) {
                        await communityService.removeTrust(
                            widget.currentUserId, widget.member.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Member removed from trusted network')),
                        );
                      } else {
                        await communityService.addTrust(
                            widget.currentUserId, widget.member.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Member added to trusted network')),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error updating trust status: $e')),
                      );
                    }
                  },
                  tooltip: isTrusted
                      ? 'Remove from trusted network'
                      : 'Add to trusted network',
                );
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
                  backgroundImage: widget.member.photoUrl != null
                      ? NetworkImage(widget.member.photoUrl!)
                      : null,
                  child: widget.member.photoUrl == null
                      ? Text(
                          widget.member.name[0].toUpperCase(),
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
                        widget.member.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (widget.member.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.member.email!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Member Info
            if (widget.member.address != null) ...[
              _InfoRow(
                icon: Icons.location_on,
                title: 'Address',
                content: widget.member.address!,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.member.phone != null) ...[
              _InfoRow(
                icon: Icons.phone,
                title: 'Phone',
                content: widget.member.phone!,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.member.bio != null) ...[
              _InfoRow(
                icon: Icons.info,
                title: 'About',
                content: widget.member.bio!,
              ),
              const SizedBox(height: 16),
            ],
            _InfoRow(
              icon: Icons.people,
              title: 'Trust Network',
              content:
                  'Trusted by ${widget.member.trustedBy.length} members • Trusts ${widget.member.trustedUsers.length} members',
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
                    .where((tool) => tool.ownerId == widget.member.id)
                    .toList();

                if (tools.isEmpty) {
                  return const Text('No tools available for borrowing');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                              currentUserId: widget.currentUserId,
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
