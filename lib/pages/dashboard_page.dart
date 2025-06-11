import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdInitialized = false;
  final FirestoreService _firestoreService = FirestoreService(); // Added
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Test ad unit ID for development
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  // Production ad unit ID
  static const String _prodAdUnitId = 'ca-app-pub-5326232965412305~2242713432';

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
    // Delay ad initialization to ensure widget is fully mounted
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _initializeAds();
      }
    });
  }

  Future<void> _initializeAds() async {
    if (!mounted) return;

    try {
      final initializationStatus = await MobileAds.instance.initialize();
      debugPrint('Initialization status: $initializationStatus');

      if (mounted) {
        setState(() {
          _isAdInitialized = true;
        });
        _initBannerAd();
      }
    } catch (e) {
      debugPrint('Error initializing MobileAds: $e');
      if (mounted) {
        setState(() {
          _isAdInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAd();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isAdInitialized) {
        _initBannerAd();
      }
    } else if (state == AppLifecycleState.paused) {
      _disposeAd();
    }
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() {
        _isAdLoaded = false;
      });
    }
  }

  void _initBannerAd() {
    if (!mounted || !_isAdInitialized) return;

    try {
      _disposeAd(); // Clean up any existing ad

      // Use test ad unit ID in debug mode
      const bool isDebug = true; // Set this based on your build configuration
      final String adUnitId = isDebug ? _testAdUnitId : _prodAdUnitId;

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Ad loaded successfully');
            if (!mounted) return;
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Ad failed to load: $error');
            ad.dispose();
            _disposeAd();
          },
          onAdOpened: (ad) => debugPrint('Ad opened'),
          onAdClosed: (ad) => debugPrint('Ad closed'),
          onAdImpression: (ad) => debugPrint('Ad impression'),
          onAdClicked: (ad) => debugPrint('Ad clicked'),
        ),
      );

      _bannerAd?.load();
    } catch (e) {
      debugPrint('Error initializing ad: $e');
      _disposeAd();
    }
  }

  Widget _buildAdWidget() {
    if (!_isAdInitialized || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, bottom: 125.0),
          child: Container(
            alignment: Alignment.centerLeft,
            height: _bannerAd?.size.height.toDouble(),
            width: _bannerAd?.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),
    );
  }

  // Future<void> _loadBorrowedTools() async { // Removed
  //   try {
  //     setState(() => _isLoading = true);
  //     final loadedTools = await dbHelper.getBorrowedTools();
  //     if (!mounted) return;
  //     setState(() {
  //       _borrowedTools.clear();
  //       _borrowedTools.addAll(loadedTools);
  //     });
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Widget _buildDrawer(BuildContext context) {
    final currentUser = AuthService().currentUser;
    String displayName = currentUser?.displayName ?? 'User';
    if (displayName.isEmpty) {
      displayName = 'User';
    }
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l10n.appTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hi, $displayName',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n.dashboard),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: Text(l10n.allTools),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ToolsPage(
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(l10n.community),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
            onTap: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              await AuthService().signOut();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
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
      drawer: _buildDrawer(context),
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
              Text(l10n.returnBy(DateFormat.yMd().format(tool.returnDate!))),
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
    if (!mounted) return;

    try {
      final allTools = await _firestoreService.getToolsStream().first;
      final availableTools = allTools.where((t) => !t.isBorrowed).toList();

      if (!mounted) return;

      if (availableTools.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noToolsAvailable),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!mounted) return;

      final selectedTool = await showDialog<Tool>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => true,
            child: AlertDialog(
              title:
                  Text(AppLocalizations.of(dialogContext)!.selectToolToBorrow),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(dialogContext).size.height * 0.6,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableTools.length,
                  itemBuilder: (BuildContext context, int index) {
                    final tool = availableTools[index];
                    return ListTile(
                      title: Text(tool.name),
                      subtitle: tool.brand != null && tool.brand!.isNotEmpty
                          ? Text(tool.brand!)
                          : null,
                      leading: tool.imagePath != null &&
                              File(tool.imagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.file(
                                File(tool.imagePath!),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.construction),
                              ),
                            )
                          : const Icon(Icons.construction),
                      onTap: () {
                        Navigator.of(dialogContext).pop(tool);
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          );
        },
      );

      if (selectedTool != null && mounted) {
        // Add a small delay to ensure the first dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        _showBorrowReturnDialog(selectedTool, isBorrowing: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tools: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBorrowReturnDialog(Tool tool, {required bool isBorrowing}) {
    if (!mounted) return;

    final borrowerNameController =
        TextEditingController(text: isBorrowing ? '' : tool.borrowedBy ?? '');
    final borrowerPhoneController = TextEditingController(
        text: isBorrowing ? '' : tool.borrowerPhone ?? '');
    final borrowerEmailController = TextEditingController(
        text: isBorrowing ? '' : tool.borrowerEmail ?? '');
    final notesController =
        TextEditingController(text: isBorrowing ? '' : tool.notes ?? '');
    DateTime? selectedReturnDate = isBorrowing ? null : tool.returnDate;
    DateTime? selectedStartDate = isBorrowing ? DateTime.now() : null;
    CommunityMember? selectedBorrower;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void handleDatePicker(bool isStartDate) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: isStartDate
                    ? (selectedStartDate ?? DateTime.now())
                    : (selectedReturnDate ?? DateTime.now()),
                firstDate: isStartDate ? DateTime(2000) : DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStartDate) {
                    selectedStartDate = picked;
                  } else {
                    selectedReturnDate = picked;
                  }
                });
              }
            }

            void showBorrowHistoryDialogLocal() async {
              List<BorrowHistory> historyToShow =
                  await _firestoreService.getBorrowHistoryStream(tool.id).first;
              if (!dialogContext.mounted) return;
              showDialog(
                context: dialogContext,
                builder: (BuildContext historyDialogContext) {
                  return AlertDialog(
                    title: Text('${tool.name} - Borrow History'),
                    content: SingleChildScrollView(
                      child: historyToShow.isEmpty
                          ? const Text('No borrow history for this tool.')
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: historyToShow.map((history) {
                                return Card(
                                  child: ListTile(
                                    title: Text(history.borrowerName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Borrowed: ${DateFormat.yMd().format(history.borrowDate)}'),
                                        Text(
                                            'Due: ${DateFormat.yMd().format(history.dueDate)}'),
                                        if (history.returnDate != null)
                                          Text(
                                              'Returned: ${DateFormat.yMd().format(history.returnDate!)}'),
                                        if (history.notes?.isNotEmpty ?? false)
                                          Text('Notes: ${history.notes}'),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    actions: [
                      TextButton(
                          child: const Text('Close'),
                          onPressed: () =>
                              Navigator.of(historyDialogContext).pop())
                    ],
                  );
                },
              );
            }

            Future<void> handleAction() async {
              final String borrowerName =
                  selectedBorrower?.name ?? borrowerNameController.text.trim();

              if (isBorrowing && borrowerName.isEmpty) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a borrower.')));
                }
                return;
              }
              if (isBorrowing &&
                  (selectedStartDate == null || selectedReturnDate == null)) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please select both start and return dates.')));
                }
                return;
              }

              try {
                Tool toolToUpdate = tool; // Start with the original tool object

                if (isBorrowing) {
                  final newHistoryEntry = BorrowHistory(
                    id: '', // Firestore will generate
                    borrowerId: selectedBorrower!.id,
                    borrowerName: selectedBorrower!.name,
                    borrowerPhone: borrowerPhoneController.text.trim(),
                    borrowerEmail: borrowerEmailController.text.trim(),
                    borrowDate: selectedStartDate!,
                    dueDate: selectedReturnDate!,
                    notes: notesController.text.trim(),
                  );
                  await _firestoreService.addBorrowHistory(
                      toolToUpdate.id, newHistoryEntry);

                  toolToUpdate = toolToUpdate.copyWith(
                    isBorrowed: true,
                    borrowedBy: selectedBorrower!.name,
                    borrowerPhone: borrowerPhoneController.text.trim(),
                    borrowerEmail: borrowerEmailController.text.trim(),
                    returnDate: selectedReturnDate,
                  );
                  await NotificationService()
                      .scheduleReturnReminder(toolToUpdate);
                } else {
                  List<BorrowHistory> historyList = await _firestoreService
                      .getBorrowHistoryStream(toolToUpdate.id)
                      .first;
                  BorrowHistory? activeHistory;
                  for (var h in historyList) {
                    if (h.returnDate == null) {
                      activeHistory = h;
                      break;
                    }
                  }

                  if (activeHistory != null) {
                    final updatedHistoryEntry = activeHistory.copyWith(
                      returnDate: DateTime.now(),
                      notes: notesController.text.trim(),
                    );
                    await _firestoreService.updateBorrowHistory(
                        toolToUpdate.id, updatedHistoryEntry);
                  } else {
                    // Fallback for data inconsistency
                  }

                  toolToUpdate = toolToUpdate.copyWith(
                    isBorrowed: false,
                    borrowedBy: null,
                    borrowerPhone: null,
                    borrowerEmail: null,
                    returnDate: null,
                  );
                  await NotificationService()
                      .cancelToolNotifications(toolToUpdate);
                }

                await _firestoreService.updateTool(toolToUpdate);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Tool "${toolToUpdate.name}" ${isBorrowing ? "borrowed" : "returned"} successfully.')),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content: Text('Action failed. Please try again: $e')),
                  );
                }
              }
            }

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: Text(isBorrowing
                    ? 'Borrow Tool: ${tool.name}'
                    : 'Return Tool: ${tool.name}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (tool.imagePath != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Image.file(File(tool.imagePath!),
                                height: 100, fit: BoxFit.cover)),
                      if (isBorrowing) ...[
                        ListTile(
                          title: const Text("Borrower"),
                          subtitle: Text(
                            selectedBorrower?.name ??
                                "Select a community member",
                          ),
                          onTap: () async {
                            final CommunityMember? result = await showDialog(
                              context: context,
                              builder: (_) => _buildSelectBorrowerDialog(),
                            );
                            if (result != null) {
                              setDialogState(() {
                                selectedBorrower = result;
                                borrowerNameController.text = result.name;
                                if (result.email != null) {
                                  borrowerEmailController.text = result.email!;
                                }
                                if (result.phone != null) {
                                  borrowerPhoneController.text = result.phone!;
                                }
                              });
                            }
                          },
                          trailing: const Icon(Icons.arrow_forward_ios),
                        ),
                      ] else ...[
                        // Displaying info for returning
                        Text('Borrowed by: ${tool.borrowedBy ?? 'N/A'}'),
                        if (tool.borrowerPhone != null)
                          Text('Phone: ${tool.borrowerPhone}'),
                        if (tool.borrowerEmail != null)
                          Text('Email: ${tool.borrowerEmail}'),
                        if (tool.returnDate != null)
                          Text(
                              'Original due date: ${DateFormat.yMd().format(tool.returnDate!)}'),
                      ],
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                            labelText:
                                isBorrowing ? "Borrow Notes" : "Return Notes",
                            hintText: isBorrowing
                                ? "Add any notes about borrowing"
                                : "Add any notes about the return"),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      if (isBorrowing) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedStartDate == null
                                ? 'Select start date'
                                : 'Start date: ${DateFormat.yMd().format(selectedStartDate!)}'),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => handleDatePicker(true),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedReturnDate == null
                              ? 'Select return date'
                              : 'Return by: ${DateFormat.yMd().format(selectedReturnDate!)}'),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => handleDatePicker(false),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('View Borrow History'),
                        onPressed: showBorrowHistoryDialogLocal,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  TextButton(
                    onPressed: handleAction,
                    child: Text(
                        isBorrowing ? 'Mark as Borrowed' : 'Mark as Returned'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectBorrowerDialog() {
    final searchController = TextEditingController();
    final communityService = CommunityService();
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Select a Borrower'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
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
                Expanded(
                  child: StreamBuilder<List<CommunityMember>>(
                    stream: communityService.getCommunityMembers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final members = snapshot.data!
                          .where((member) => (searchQuery.isEmpty ||
                              member.name
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase())))
                          .toList();

                      if (members.isEmpty) {
                        return const Center(child: Text('No members found'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(member.name.isNotEmpty
                                  ? member.name[0]
                                  : '?'),
                            ),
                            title: Text(member.name),
                            subtitle: Text(
                                'Rating: ${member.rating.toStringAsFixed(1)}'),
                            onTap: () {
                              Navigator.of(context).pop(member);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
