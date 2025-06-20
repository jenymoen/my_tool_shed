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
    // Implementation of _showSelectToolToBorrowDialog method
  }

  void _showBorrowReturnDialog(Tool tool, {required bool isBorrowing}) {
    // Implementation of _showBorrowReturnDialog method
  }

  Widget _buildSelectBorrowerDialog() {
    // Implementation of _buildSelectBorrowerDialog method
    return const SizedBox.shrink();
  }
}
