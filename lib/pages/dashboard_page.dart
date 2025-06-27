import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_tool_shed/models/community_member.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/auth_service.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/services/firestore_service.dart';
import 'package:my_tool_shed/services/notification_service.dart';
import 'package:my_tool_shed/pages/tools_page.dart';
import 'package:my_tool_shed/pages/login_page.dart';
import 'package:my_tool_shed/pages/profile_page.dart';
import 'package:my_tool_shed/pages/settings_page.dart';
import 'package:my_tool_shed/pages/community/community_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_tool_shed/utils/date_formatter.dart';
import 'package:my_tool_shed/utils/logger.dart';
import 'package:my_tool_shed/widgets/app_drawer.dart';
import 'package:my_tool_shed/widgets/ad_banner_widget.dart';
import 'package:my_tool_shed/utils/ad_constants.dart';

class DashboardPage extends StatefulWidget {
  final Function(Locale) onLocaleChanged;

  const DashboardPage({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  // final List<Tool> _borrowedTools = []; // Replaced by StreamBuilder
  // bool _isLoading = true; // Replaced by StreamBuilder states
  final FirestoreService _firestoreService = FirestoreService(); // Added
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Test ad unit ID for development
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  // Production ad unit ID
  static const String _prodAdUnitId = 'ca-app-pub-5326232965412305/9406053435';

  List<Tool> _filterBorrowedTools(List<Tool> allTools) {
    if (allTools.isEmpty) return [];
    return allTools.where((tool) => tool.isBorrowed).toList();
  }

  List<Tool> _getDueSoonTools(List<Tool> borrowedTools) {
    if (borrowedTools.isEmpty) return [];
    final now = DateTime.now();
    return borrowedTools.where((tool) {
      if (tool.returnDate != null) {
        final daysUntilDue = tool.returnDate!.difference(now).inDays;
        return daysUntilDue <= 7 && daysUntilDue >= 0;
      }
      return false;
    }).toList()
      ..sort((a, b) {
        final aDate =
            a.returnDate ?? DateTime.now().add(const Duration(days: 36500));
        final bDate =
            b.returnDate ?? DateTime.now().add(const Duration(days: 36500));
        return aDate.compareTo(bDate);
      });
  }

  List<Tool> _getOverdueTools(List<Tool> borrowedTools) {
    if (borrowedTools.isEmpty) return [];
    final now = DateTime.now();
    return borrowedTools.where((tool) {
      if (tool.returnDate != null) {
        final daysUntilDue = tool.returnDate!.difference(now).inDays;
        return daysUntilDue < 0;
      }
      return false;
    }).toList()
      ..sort((a, b) {
        final aDate =
            a.returnDate ?? DateTime.now().add(const Duration(days: 36500));
        final bDate =
            b.returnDate ?? DateTime.now().add(const Duration(days: 36500));
        return aDate.compareTo(bDate);
      });
  }

  List<Tool> _getRegularBorrowedTools(List<Tool> borrowedTools) {
    if (borrowedTools.isEmpty) return [];
    final dueSoonTools = _getDueSoonTools(borrowedTools);
    final overdueTools = _getOverdueTools(borrowedTools);
    return borrowedTools
        .where((tool) =>
            !dueSoonTools.contains(tool) && !overdueTools.contains(tool))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  (String, Color) _getToolStatus(Tool tool, BuildContext context) {
    if (!tool.isBorrowed) {
      return ('Available', Colors.green);
    }

    final now = DateTime.now();
    if (tool.returnDate != null) {
      final daysUntilDue = tool.returnDate!.difference(now).inDays;
      if (daysUntilDue < 0) {
        return ('Overdue by ${-daysUntilDue} days', Colors.red);
      } else if (daysUntilDue <= 7) {
        return ('Due in $daysUntilDue days', Colors.orange);
      } else {
        return (
          'Due in $daysUntilDue days',
          Theme.of(context).colorScheme.secondary
        );
      }
    }
    return ('Borrowed', Colors.green);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
  }

  Widget _buildAdWidget() {
    return AdBannerWidget(
      adUnitId: AdConstants.getAdUnitId(
        AdConstants.dashboardBannerAdUnitId,
        isDebug: false, // Set to true for test ads, false for production
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(l10n.dashboard),
        leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      ),
      drawer: AppDrawer(onLocaleChanged: widget.onLocaleChanged),
      body: StreamBuilder<List<Tool>>(
        stream: _firestoreService.getToolsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading tools: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.noToolsAvailable));
          }

          final allTools = snapshot.data!;
          final borrowedTools = _filterBorrowedTools(allTools);

          if (borrowedTools.isEmpty) {
            return Center(child: Text(l10n.noToolsAvailable));
          }

          final overdueTools = _getOverdueTools(borrowedTools);
          final dueSoonTools = _getDueSoonTools(borrowedTools);
          final regularBorrowedTools = _getRegularBorrowedTools(borrowedTools);

          List<Widget> listItems = [];

          if (overdueTools.isNotEmpty) {
            listItems.add(Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${l10n.overdue} (${overdueTools.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ));
            listItems.addAll(
                overdueTools.map((tool) => _buildToolTile(tool)).toList());
            listItems.add(const Divider());
          }

          if (dueSoonTools.isNotEmpty) {
            listItems.add(Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${l10n.dueSoon} (${dueSoonTools.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ));
            listItems.addAll(
                dueSoonTools.map((tool) => _buildToolTile(tool)).toList());
            listItems.add(const Divider());
          }

          if (regularBorrowedTools.isNotEmpty) {
            listItems.add(Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  '${l10n.otherBorrowedItems} (${regularBorrowedTools.length})',
                  style: Theme.of(context).textTheme.titleMedium),
            ));
            listItems.addAll(regularBorrowedTools
                .map((tool) => _buildToolTile(tool))
                .toList());
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: listItems,
                ),
              ),
              _buildAdWidget(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'borrow_tool_dashboard',
        onPressed: () => _showSelectToolToBorrowDialog(context),
        tooltip: l10n.borrowTool,
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(l10n.borrowTool),
      ),
    );
  }

  Widget _buildToolTile(Tool tool) {
    final l10n = AppLocalizations.of(context)!;
    final (statusText, statusColor) = _getToolStatus(tool, context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: tool.imagePath != null && File(tool.imagePath!).existsSync()
            ? SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(tool.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.construction, size: 40),
                  ),
                ),
              )
            : const Icon(Icons.construction, size: 40),
        title: Text(
          tool.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            if (tool.brand != null && tool.brand!.isNotEmpty)
              Text(l10n.brand(tool.brand!)),
            Text(l10n.borrowedBy(tool.borrowedBy ?? 'N/A')),
            if (tool.returnDate != null)
              Text('Return by: ${DateFormatter.format(tool.returnDate!)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.undo),
          tooltip: l10n.returnTool,
          onPressed: () => _showBorrowReturnDialog(tool, isBorrowing: false),
        ),
        onTap: () => _showBorrowReturnDialog(tool, isBorrowing: false),
      ),
    );
  }

  void _showSelectToolToBorrowDialog(BuildContext pageContext) async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = _firestoreService.currentUser;
    final communityService = CommunityService();

    List<Tool> availableTools = [];
    List<CommunityMember> communityMembers = [];
    Tool? selectedTool;
    CommunityMember? selectedBorrower;
    DateTime? startDate;
    DateTime? returnDate;

    try {
      final allTools = await _firestoreService.getToolsStream().first;
      availableTools = allTools.where((tool) => !tool.isBorrowed).toList();
      communityMembers = await communityService.getCommunityMembers().first;
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
      return;
    }

    if (availableTools.isEmpty) {
      if (pageContext.mounted) {
        showDialog(
          context: pageContext,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(l10n.borrowTool),
              content: Text(l10n.noToolsAvailable),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    showDialog(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate(bool isStartDate) async {
              final now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: (isStartDate ? startDate : returnDate) ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStartDate) {
                    startDate = picked;
                    if (returnDate != null &&
                        returnDate!.isBefore(startDate!)) {
                      returnDate = null;
                    }
                  } else {
                    returnDate = picked;
                  }
                });
              }
            }

            return AlertDialog(
              title: Text(l10n.borrowTool),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Tool>(
                      value: selectedTool,
                      onChanged: (Tool? newValue) {
                        setDialogState(() {
                          selectedTool = newValue;
                        });
                      },
                      items: availableTools
                          .map<DropdownMenuItem<Tool>>((Tool tool) {
                        return DropdownMenuItem<Tool>(
                          value: tool,
                          child: Text(tool.name),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Select Tool',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Start Date',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: () => selectDate(true),
                      child: Text(startDate == null
                          ? 'Select Date'
                          : DateFormatter.format(startDate!)),
                    ),
                    const SizedBox(height: 16),
                    Text('Return Date',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed:
                          startDate == null ? null : () => selectDate(false),
                      child: Text(returnDate == null
                          ? 'Select Date'
                          : DateFormatter.format(returnDate!)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CommunityMember>(
                      value: selectedBorrower,
                      hint: const Text('Choose a borrower'),
                      onChanged: (CommunityMember? newValue) {
                        setDialogState(() {
                          selectedBorrower = newValue;
                        });
                      },
                      items: communityMembers
                          .map<DropdownMenuItem<CommunityMember>>(
                              (CommunityMember member) {
                        return DropdownMenuItem<CommunityMember>(
                          value: member,
                          child: Text(member.name),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Borrower Name',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (selectedTool != null &&
                          startDate != null &&
                          returnDate != null &&
                          selectedBorrower != null)
                      ? () async {
                          try {
                            final updatedTool = selectedTool!.copyWith(
                              isBorrowed: true,
                              borrowedBy: selectedBorrower!.id,
                              returnDate: returnDate,
                            );
                            await _firestoreService.updateTool(updatedTool);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Successfully borrowed ${selectedTool!.name}'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                SnackBar(
                                    content: Text('Error borrowing tool: $e')),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBorrowReturnDialog(Tool tool, {required bool isBorrowing}) {
    // Simple placeholder implementation
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isBorrowing ? 'Borrow Tool' : 'Return Tool'),
          content: Text(
              '${isBorrowing ? 'Borrow' : 'Return'} ${tool.name} functionality coming soon...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectBorrowerDialog() {
    // Implementation of _buildSelectBorrowerDialog method
    return const SizedBox.shrink();
  }
}
