import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/firestore_service.dart';
import 'package:my_tool_shed/services/notification_service.dart';
// import 'package:my_tool_shed/pages/qr_scanner_page.dart';
// import 'package:my_tool_shed/services/qr_service.dart';

// import 'package:path/path.dart' as p;
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_tool_shed/pages/tools_page.dart'; // For drawer navigation
import 'package:my_tool_shed/services/auth_service.dart'; // Added for logout
import 'package:my_tool_shed/pages/login_page.dart'; // Added for navigation after logout
import 'package:my_tool_shed/pages/profile_page.dart'; // Added for ProfilePage navigation

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  // final List<Tool> _borrowedTools = []; // Replaced by StreamBuilder
  // bool _isLoading = true; // Replaced by StreamBuilder states
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  // final dbHelper = DatabaseHelper.instance; // Replaced
  final FirestoreService _firestoreService = FirestoreService(); // Added
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _brandOptions = [
    'Bosch',
    'Makita',
    'DeWalt',
    'Milwaukee',
    'Ryobi',
    'Stanley',
    'Craftsman',
    'Other'
  ];
  // String? _selectedBrand; // Not used directly for adding on dashboard, but keep if dialogs are shared

  List<Tool> _filterBorrowedTools(List<Tool> allTools) {
    return allTools.where((tool) => tool.isBorrowed).toList();
  }

  List<Tool> _getDueSoonTools(List<Tool> borrowedTools) {
    final now = DateTime.now();
    return borrowedTools.where((tool) {
      if (tool.returnDate != null) {
        final daysUntilDue = tool.returnDate!.difference(now).inDays;
        return daysUntilDue <= 7 &&
            daysUntilDue >= 0; // Due within a week and not overdue
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
    final now = DateTime.now();
    return borrowedTools.where((tool) {
      if (tool.returnDate != null) {
        final daysUntilDue = tool.returnDate!.difference(now).inDays;
        return daysUntilDue < 0; // Overdue
      }
      return false;
    }).toList()
      ..sort((a, b) {
        final aDate =
            a.returnDate ?? DateTime.now().add(const Duration(days: 36500));
        final bDate =
            b.returnDate ?? DateTime.now().add(const Duration(days: 36500));
        return aDate.compareTo(bDate); // Sooner overdue dates first
      });
  }

  List<Tool> _getRegularBorrowedTools(List<Tool> borrowedTools) {
    final dueSoonTools = _getDueSoonTools(borrowedTools);
    final overdueTools = _getOverdueTools(borrowedTools);
    return borrowedTools
        .where((tool) =>
            !dueSoonTools.contains(tool) && !overdueTools.contains(tool))
        .toList()
      ..sort((a, b) {
        // Optional: sort regular tools by name or other criteria
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  (String, Color) _getToolStatus(Tool tool, BuildContext context) {
    final now = DateTime.now();
    if (tool.isBorrowed && tool.returnDate != null) {
      final daysUntilDue = tool.returnDate!.difference(now).inDays;
      if (daysUntilDue < 0) {
        return ('Overdue by ${-daysUntilDue} days', Colors.red);
      } else if (daysUntilDue <= 7) {
        return ('Due in $daysUntilDue days', Colors.orange);
      } else {
        return (
          'Due in $daysUntilDue days',
          Theme.of(context).colorScheme.secondary
        ); // Or a less prominent color
      }
    }
    return (
      'Borrowed',
      Colors.green
    ); // Should ideally not happen if date is always set
  }

  @override
  void initState() {
    super.initState();
    // _loadBorrowedTools(); // Replaced by StreamBuilder
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5326232965412305~2242713432',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
                  'My Tool Shed',
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
            title: const Text('Dashboard (Borrowed Tools)'),
            onTap: () {
              Navigator.pop(context);
              // No need to reload, already on this page or StreamBuilder handles it
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('All Tools'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                // Or push if you want back navigation
                context,
                MaterialPageRoute(builder: (context) => const ToolsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            return const Center(
                child: Text('No tools found. Visit "All Tools" to add some.'));
          }

          final allTools = snapshot.data!;
          final borrowedTools = _filterBorrowedTools(allTools);

          if (borrowedTools.isEmpty) {
            return const Center(
                child: Text(
                    'No tools currently borrowed. Borrow one from "All Tools" or use the FAB.'));
          }

          final overdueTools = _getOverdueTools(borrowedTools);
          final dueSoonTools = _getDueSoonTools(borrowedTools);
          final regularBorrowedTools = _getRegularBorrowedTools(borrowedTools);

          List<Widget> listItems = [];

          if (overdueTools.isNotEmpty) {
            listItems.add(Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Overdue (${overdueTools.length})',
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
              child: Text('Due Soon (${dueSoonTools.length})',
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
                  'Other Borrowed Items (${regularBorrowedTools.length})',
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
                  // Changed from ListView.builder to simple ListView for sections
                  children: listItems,
                ),
              ),
              if (_isAdLoaded)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
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
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'borrow_tool_dashboard',
        onPressed: () => _showSelectToolToBorrowDialog(context),
        tooltip: 'Borrow a Tool',
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text("Borrow Tool"),
      ),
    );
  }

  Widget _buildToolTile(Tool tool) {
    final (statusText, statusColor) = _getToolStatus(tool, context);
    return ListTile(
      leading: tool.imagePath != null && File(tool.imagePath!).existsSync()
          ? SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(File(tool.imagePath!),
                      fit: BoxFit.cover,
                      frameBuilder: (context, child, frame,
                              wasSynchronouslyLoaded) =>
                          frame == null
                              ? const Center(child: CircularProgressIndicator())
                              : child,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.construction, size: 40))))
          : const Icon(Icons.construction, size: 40),
      title: Text(tool.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText,
              style:
                  TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          if (tool.brand != null && tool.brand!.isNotEmpty)
            Text('Brand: ${tool.brand}'),
          // Note: For dashboard, tool.borrowedBy should always be populated if it's in this list
          Text('Borrowed by: ${tool.borrowedBy ?? 'N/A'}'),
          if (tool.returnDate != null)
            Text('Return by: ${DateFormat.yMd().format(tool.returnDate!)}'),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.undo), // Icon for returning a tool
        tooltip: 'Return Tool',
        onPressed: () => _showBorrowReturnDialog(tool, isBorrowing: false),
      ),
      onTap: () =>
          _showBorrowReturnDialog(tool, isBorrowing: false), // Tap to return
    );
  }

  void _showSelectToolToBorrowDialog(BuildContext pageContext) async {
    // pageContext to avoid conflict
    // Use FirestoreService to get available tools
    final allTools = await _firestoreService.getToolsStream().first;
    final availableTools = allTools.where((t) => !t.isBorrowed).toList();

    if (!pageContext.mounted) return;

    if (availableTools.isEmpty) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
            content: Text('No tools are currently available to borrow.')),
      );
      return;
    }

    showDialog(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Tool to Borrow'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTools.length,
              itemBuilder: (BuildContext context, int index) {
                final tool = availableTools[index];
                return ListTile(
                  title: Text(tool.name),
                  leading: tool.imagePath != null &&
                          File(tool.imagePath!).existsSync()
                      ? Image.file(File(tool.imagePath!),
                          width: 40, height: 40, fit: BoxFit.cover)
                      : const Icon(Icons.construction),
                  onTap: () {
                    Navigator.of(dialogContext).pop(); // Close this dialog
                    _showBorrowReturnDialog(tool,
                        isBorrowing:
                            true); // Open borrow dialog for selected tool
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Updated _showBorrowReturnDialog to handle both borrowing and returning
  // Needs to be fully refactored for Firestore
  void _showBorrowReturnDialog(Tool tool, {required bool isBorrowing}) {
    final borrowerNameController =
        TextEditingController(text: isBorrowing ? '' : tool.borrowedBy ?? '');
    final borrowerPhoneController = TextEditingController(
        text: isBorrowing ? '' : tool.borrowerPhone ?? '');
    final borrowerEmailController = TextEditingController(
        text: isBorrowing ? '' : tool.borrowerEmail ?? '');
    // For returns, notes could be existing tool.notes or new return notes.
    // For borrows, notes are new.
    final notesController =
        TextEditingController(text: isBorrowing ? '' : tool.notes ?? '');
    DateTime? selectedReturnDate = isBorrowing ? null : tool.returnDate;
    DateTime? selectedStartDate = isBorrowing ? DateTime.now() : null;

    showDialog(
      context: context, // Assuming this.context is the Page's context
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleDatePicker(bool isStartDate) async {
              final DateTime? picked = await showDatePicker(
                context: dialogContext,
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

            Future<void> handleAction() async {
              final String borrowerName = borrowerNameController.text.trim();

              if (isBorrowing &&
                  (borrowerName.isEmpty ||
                      selectedReturnDate == null ||
                      selectedStartDate == null)) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please enter borrower name and select both start and return dates.')),
                  );
                }
                return;
              }

              try {
                Tool toolToUpdate = Tool(
                    // Create a mutable copy or fetch fresh if necessary
                    id: tool.id,
                    name: tool.name,
                    imagePath: tool.imagePath,
                    brand: tool.brand,
                    isBorrowed: tool.isBorrowed,
                    returnDate: tool.returnDate,
                    borrowedBy: tool.borrowedBy,
                    borrowHistory: List<BorrowHistory>.from(tool.borrowHistory),
                    borrowerPhone: tool.borrowerPhone,
                    borrowerEmail: tool.borrowerEmail,
                    notes: tool.notes, // Keep existing notes unless overridden
                    qrCode: tool.qrCode,
                    category: tool.category);

                if (isBorrowing) {
                  // Borrowing logic
                  final newHistoryEntry = BorrowHistory(
                    id: '', // Firestore generates
                    borrowerId: _firestoreService.currentUser?.uid ??
                        'borrow_action_user',
                    borrowerName: borrowerName,
                    borrowerPhone: borrowerPhoneController.text.trim(),
                    borrowerEmail: borrowerEmailController.text.trim().isEmpty
                        ? null
                        : borrowerEmailController.text.trim(),
                    borrowDate: selectedStartDate!,
                    dueDate: selectedReturnDate!,
                    notes: notesController.text.trim(),
                  );
                  await _firestoreService.addBorrowHistory(
                      toolToUpdate.id, newHistoryEntry);

                  toolToUpdate.isBorrowed = true;
                  toolToUpdate.borrowedBy = borrowerName;
                  toolToUpdate.borrowerPhone =
                      borrowerPhoneController.text.trim();
                  toolToUpdate.borrowerEmail =
                      borrowerEmailController.text.trim().isEmpty
                          ? null
                          : borrowerEmailController.text.trim();
                  toolToUpdate.returnDate = selectedReturnDate;
                  // toolToUpdate.notes = notesController.text.trim(); // Overwrite tool notes with borrow notes
                  await NotificationService()
                      .scheduleReturnReminder(toolToUpdate);
                } else {
                  // Returning logic
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
                    final updatedHistoryEntry = BorrowHistory(
                      id: activeHistory.id,
                      borrowerId: activeHistory.borrowerId,
                      borrowerName: activeHistory.borrowerName,
                      borrowerPhone: activeHistory.borrowerPhone,
                      borrowerEmail: activeHistory.borrowerEmail,
                      borrowDate: activeHistory.borrowDate,
                      dueDate: activeHistory.dueDate,
                      returnDate: DateTime.now(),
                      notes:
                          notesController.text.trim(), // These are return notes
                    );
                    await _firestoreService.updateBorrowHistory(
                        toolToUpdate.id, updatedHistoryEntry);
                  } else {
                    // Fallback if no active history found (should be rare for a borrowed tool)
                    final newHistoryEntry = BorrowHistory(
                      id: '', // Firestore generates
                      borrowerId: _firestoreService.currentUser?.uid ??
                          'return_action_user',
                      borrowerName:
                          toolToUpdate.borrowedBy ?? "Unknown on return",
                      borrowDate: toolToUpdate.returnDate
                              ?.subtract(const Duration(days: 1)) ??
                          DateTime.now().subtract(const Duration(days: 1)),
                      dueDate: toolToUpdate.returnDate ?? DateTime.now(),
                      returnDate: DateTime.now(),
                      notes: "Tool returned. ${notesController.text.trim()}",
                    );
                    await _firestoreService.addBorrowHistory(
                        toolToUpdate.id, newHistoryEntry);
                  }

                  toolToUpdate.isBorrowed = false;
                  toolToUpdate.borrowedBy = null;
                  toolToUpdate.borrowerPhone = null;
                  toolToUpdate.borrowerEmail = null;
                  toolToUpdate.returnDate = null;
                  // toolToUpdate.notes = notesController.text.trim(); // Could update tool notes with return notes
                  await NotificationService()
                      .cancelToolNotifications(toolToUpdate);
                }

                await _firestoreService.updateTool(toolToUpdate);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  // Use page's context
                  SnackBar(
                      content: Text(
                          'Tool \"${toolToUpdate.name}\" ${isBorrowing ? "borrowed" : "returned"} successfully.')),
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Action failed: $e')),
                  );
                }
              }
            }

            void showBorrowHistoryDialogLocal() async {
              // Renamed to avoid conflict
              List<BorrowHistory> historyToShow =
                  await _firestoreService.getBorrowHistoryStream(tool.id).first;
              if (!dialogContext.mounted)
                return; // Check before showing another dialog
              showDialog(
                context:
                    dialogContext, // Use the current dialog's context for nesting
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

            return AlertDialog(
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
                      TextField(
                        controller: borrowerNameController,
                        decoration: const InputDecoration(
                            labelText: "Borrower Name",
                            hintText: "Enter borrower's name"),
                        autofocus: true,
                      ),
                      TextField(
                        controller: borrowerPhoneController,
                        decoration: const InputDecoration(
                            labelText: "Phone Number",
                            hintText: "Enter borrower's phone"),
                        keyboardType: TextInputType.phone,
                      ),
                      TextField(
                        controller: borrowerEmailController,
                        decoration: const InputDecoration(
                            labelText: "Email",
                            hintText: "Enter borrower's email"),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
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
            );
          },
        );
      },
    );
  }
}
