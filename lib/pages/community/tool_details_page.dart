import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/models/tool_rating.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/borrow_request_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_tool_shed/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ToolDetailsPage extends StatefulWidget {
  final Tool tool;
  final String currentUserId;

  const ToolDetailsPage({
    super.key,
    required this.tool,
    required this.currentUserId,
  });

  @override
  State<ToolDetailsPage> createState() => _ToolDetailsPageState();
}

class _ToolDetailsPageState extends State<ToolDetailsPage> {
  late Tool _tool;
  final _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _tool = widget.tool;
  }

  void _updateTool(Tool updatedTool) {
    setState(() {
      _tool = updatedTool;
    });
  }

  void _showBorrowRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => BorrowRequestDialog(
        tool: _tool,
        onSubmit: (startDate, endDate, notes) {
          // TODO: Handle borrow request submission
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Borrow request submitted'),
            ),
          );
        },
      ),
    );
  }

  void _showAddBorrowerDialog(List<String> allowedBorrowers,
      Function(List<String>) onBorrowersUpdated) {
    final searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Allowed Borrowers'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search community members...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<CommunityMember>>(
                  stream: _communityService.getCommunityMembers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final members = snapshot.data!
                        .where((member) =>
                            member.id != _tool.ownerId && // Don't show owner
                            !allowedBorrowers.contains(member
                                .id) && // Don't show already added members
                            (searchQuery.isEmpty ||
                                member.name
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase())))
                        .toList();

                    if (members.isEmpty) {
                      return const Text('No members found');
                    }

                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(member.name[0]),
                            ),
                            title: Text(member.name),
                            subtitle: Text(
                                'Rating: ${member.rating.toStringAsFixed(1)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  allowedBorrowers.add(member.id);
                                });
                                onBorrowersUpdated(allowedBorrowers);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCommunitySharingDialog() {
    bool requiresApproval = _tool.requiresApproval;
    List<String> allowedBorrowers = List<String>.from(_tool.allowedBorrowers);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Community Sharing Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Require Approval'),
                subtitle: const Text(
                    'Approve each borrow request before allowing the tool to be borrowed'),
                value: requiresApproval,
                onChanged: (value) {
                  setState(() {
                    requiresApproval = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Allowed Borrowers',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (allowedBorrowers.isEmpty)
                const Text('All community members can borrow this tool')
              else
                StreamBuilder<List<CommunityMember>>(
                  stream: _communityService.getCommunityMembers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final members = snapshot.data!
                        .where((member) => allowedBorrowers.contains(member.id))
                        .toList();

                    return Column(
                      children: [
                        ...members.map((member) => ListTile(
                              leading: CircleAvatar(
                                child: Text(member.name[0]),
                              ),
                              title: Text(member.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    allowedBorrowers.remove(member.id);
                                  });
                                },
                              ),
                            )),
                        TextButton.icon(
                          onPressed: () => _showAddBorrowerDialog(
                              allowedBorrowers, (updated) {
                            setState(() {
                              allowedBorrowers.clear();
                              allowedBorrowers.addAll(updated);
                            });
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Borrower'),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  AppLogger.info('Updating tool sharing settings...');
                  AppLogger.debug('Tool ID: ${_tool.id}');
                  AppLogger.debug('Current settings:');
                  AppLogger.debug(
                      '- isAvailableForCommunity: ${_tool.isAvailableForCommunity}');
                  AppLogger.debug('- requiresApproval: $requiresApproval');
                  AppLogger.debug('- allowedBorrowers: $allowedBorrowers');

                  final updatedTool = _tool.copyWith(
                    isAvailableForCommunity: true,
                    requiresApproval: requiresApproval,
                    allowedBorrowers: allowedBorrowers,
                  );

                  AppLogger.debug('Updated settings:');
                  AppLogger.debug(
                      '- isAvailableForCommunity: ${updatedTool.isAvailableForCommunity}');
                  AppLogger.debug(
                      '- requiresApproval: ${updatedTool.requiresApproval}');
                  AppLogger.debug(
                      '- allowedBorrowers: ${updatedTool.allowedBorrowers}');

                  await _communityService
                      .updateToolSharingSettings(updatedTool);
                  AppLogger.info('Tool sharing settings updated successfully');

                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _tool = updatedTool;
                    });
                    AppLogger.debug('Tool state updated in UI:');
                    AppLogger.debug(
                        '- isAvailableForCommunity: ${_tool.isAvailableForCommunity}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Tool is now available for community sharing'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  AppLogger.error(
                      'Error updating tool sharing settings', e, stackTrace);
                  if (context.mounted) {
                    String errorMessage = 'Failed to update sharing settings';
                    if (e.toString().contains('permission-denied')) {
                      errorMessage =
                          'You do not have permission to update this tool';
                    } else if (e.toString().contains('not-found')) {
                      errorMessage = 'Tool not found in database';
                    } else if (e.toString().contains('unavailable')) {
                      errorMessage =
                          'Network error. Please check your connection';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Dismiss',
                          textColor: Colors.white,
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Make Available'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFromCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Community'),
        content: const Text(
            'Are you sure you want to remove this tool from community sharing? This will prevent other members from borrowing it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                AppLogger.info('Removing tool from community sharing...');
                AppLogger.debug('Tool ID: ${_tool.id}');

                final updatedTool = _tool.copyWith(
                  isAvailableForCommunity: false,
                  requiresApproval: false,
                  allowedBorrowers: [],
                );

                await _communityService.updateToolSharingSettings(updatedTool);
                AppLogger.info(
                    'Tool removed from community sharing successfully');

                if (context.mounted) {
                  Navigator.pop(context);
                  _updateTool(updatedTool);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tool removed from community sharing'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e, stackTrace) {
                AppLogger.error('Error removing tool from community sharing', e,
                    stackTrace);
                if (context.mounted) {
                  String errorMessage = 'Failed to remove tool from community';
                  if (e.toString().contains('permission-denied')) {
                    errorMessage =
                        'You do not have permission to update this tool';
                  } else if (e.toString().contains('not-found')) {
                    errorMessage = 'Tool not found in database';
                  } else if (e.toString().contains('unavailable')) {
                    errorMessage =
                        'Network error. Please check your connection';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building ToolDetailsPage:');
    AppLogger.debug('- Tool ID: ${_tool.id}');
    AppLogger.debug(
        '- isAvailableForCommunity: ${_tool.isAvailableForCommunity}');
    AppLogger.debug(
        '- isOwner: ${_tool.ownerId == FirebaseAuth.instance.currentUser?.uid}');

    return Scaffold(
      appBar: AppBar(
        title: Text(_tool.name),
        actions: [
          if (_tool.ownerId == FirebaseAuth.instance.currentUser?.uid)
            IconButton(
              icon: Icon(
                _tool.isAvailableForCommunity
                    ? Icons.people
                    : Icons.people_outline,
                color: _tool.isAvailableForCommunity ? Colors.black : null,
              ),
              onPressed: () {
                if (_tool.isAvailableForCommunity) {
                  _showRemoveFromCommunityDialog();
                } else {
                  _showCommunitySharingDialog();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _tool.imagePath != null
                  ? Image.network(
                      _tool.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        AppLogger.error(
                            'Error loading tool image', error, stackTrace);
                        return Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Icon(
                            Icons.build,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    )
                  : Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.build,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool Info
                  Text(
                    _tool.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_tool.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _tool.brand!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 24,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tool.communityRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        ' (${_tool.totalCommunityRatings} ratings)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Owner Info
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 24,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Owner',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _tool.ownerName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Additional Info
                  if (_tool.location != null) ...[
                    _InfoRow(
                      icon: Icons.location_on,
                      title: 'Location',
                      content: _tool.location!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_tool.condition != null) ...[
                    _InfoRow(
                      icon: Icons.build,
                      title: 'Condition',
                      content: _tool.condition!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _InfoRow(
                    icon: Icons.calendar_today,
                    title: 'Last Maintenance',
                    content: _tool.lastMaintenanceDate.toString().split(' ')[0],
                  ),
                  if (_tool.maintenanceNotes != null) ...[
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.note,
                      title: 'Maintenance Notes',
                      content: _tool.maintenanceNotes!,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Community Sharing Status
                  if (_tool.isAvailableForCommunity) ...[
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Available for Community',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tool.requiresApproval
                                  ? 'Borrow requests require approval'
                                  : 'Open for immediate borrowing',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ratings
                  Text(
                    'Ratings & Reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<ToolRating>>(
                    stream: _communityService.getToolRatings(_tool.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        AppLogger.error(
                            'Error loading tool ratings', snapshot.error);
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final ratings = snapshot.data!;
                      if (ratings.isEmpty) {
                        return const Text('No ratings yet');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ratings.length,
                        itemBuilder: (context, index) {
                          final rating = ratings[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(rating.rating.toString()),
                              ),
                              title: Text(rating.comment ?? ''),
                              subtitle: Text(
                                'By ${rating.raterName} on ${rating.ratingDate.toString().split(' ')[0]}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _tool.ownerId != FirebaseAuth.instance.currentUser?.uid &&
                  _tool.isAvailableForCommunity
              ? FloatingActionButton.extended(
                  onPressed: _showBorrowRequestDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Request to Borrow'),
                )
              : null,
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
      children: [
        Icon(
          icon,
          size: 24,
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
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
