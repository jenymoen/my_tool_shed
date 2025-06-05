import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/member_card.dart';
import 'package:my_tool_shed/pages/community/member_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityMembersPage extends StatelessWidget {
  const CommunityMembersPage({super.key});

  void _showAddTrustedMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final bioController = TextEditingController();
    final communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Trusted Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter member name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter member email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter member phone',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter member address',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Enter member bio',
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                try {
                  final newMember = CommunityMember(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(), // Temporary ID
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
                    trustedBy: [
                      currentUserId
                    ], // Add current user as first trust
                  );

                  await communityService.addCommunityMember(newMember);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${newMember.name} added as trusted member')),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error adding member: $e')),
                    );
                  }
                }
              },
              child: const Text('Add Member'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTrustedMemberDialog(context),
        child: const Icon(Icons.person_add),
        tooltip: 'Add Trusted Member',
      ),
      body: StreamBuilder<List<CommunityMember>>(
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

          final members = snapshot.data!;

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No community members yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add trusted members to start building your community',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
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
      ),
    );
  }
}
