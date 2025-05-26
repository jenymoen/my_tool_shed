import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/database_helper.dart';
import 'package:my_tool_shed/services/notification_service.dart';
// import 'package:my_tool_shed/pages/qr_scanner_page.dart';
// import 'package:my_tool_shed/services/qr_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_tool_shed/pages/tools_page.dart'; // For drawer navigation

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final List<Tool> _borrowedTools = []; // Renamed from _tools
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final dbHelper = DatabaseHelper.instance; // Added this line
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Added for Drawer

  // Predefined list of brands
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
  String? _selectedBrand;

  // Helper method to get tools that are due soon or need maintenance (operates on _borrowedTools)
  List<Tool> _getDueSoonTools() {
    final now = DateTime.now();
    return _borrowedTools.where((tool) {
      if (tool.returnDate != null) {
        final daysUntilDue = tool.returnDate!.difference(now).inDays;
        return daysUntilDue <= 7; // Due within a week
      }
      // Removed maintenance check from here
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

  // Helper method to get regular tools (not due soon, from _borrowedTools)
  List<Tool> _getRegularTools() {
    final dueSoonTools = _getDueSoonTools();
    return _borrowedTools
        .where((tool) => !dueSoonTools.contains(tool))
        .toList(); // Operates on _borrowedTools
  }

  // Helper method to get status text and color for a tool
  (String, Color) _getToolStatus(Tool tool, BuildContext context) {
    final now = DateTime.now();
    if (tool.returnDate != null) {
      final daysUntilDue = tool.returnDate!.difference(now).inDays;
      if (daysUntilDue < 0) {
        return ('Overdue by ${-daysUntilDue} days', Colors.red);
      } else if (daysUntilDue <= 7) {
        return ('Due in $daysUntilDue days', Colors.orange);
      } else {
        return ('Borrowed, Due in $daysUntilDue days', Colors.green);
      }
    }
    // Removed maintenance checks from here too for consistency, though it was mostly borrow-focused.
    return ('Borrowed', Colors.green); // Fallback status for a borrowed tool
  }

  @override
  void initState() {
    super.initState();
    _loadBorrowedTools(); // Loads tools when the widget is initilized
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
          print('Ad failed to load on Dashboard: $error');
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

  // --- SharePreferences Logic --- // This comment can be removed or updated
  Future<void> _loadBorrowedTools() async {
    try {
      setState(() => _isLoading = true);
      final loadedTools =
          await dbHelper.getBorrowedTools(); // Fetches only borrowed tools
      if (!mounted) return;
      setState(() {
        _borrowedTools.clear();
        _borrowedTools.addAll(loadedTools);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method to show the Borrow/Return dialog - TO BE REPLACED with version from ToolsPage
  void _showBorrowReturnDialog(Tool tool) {
    final borrowerNameController =
        TextEditingController(text: tool.borrowedBy ?? '');
    final borrowerPhoneController =
        TextEditingController(text: tool.borrowerPhone ?? '');
    final borrowerEmailController =
        TextEditingController(text: tool.borrowerEmail ?? '');
    final notesController = TextEditingController(text: tool.notes ?? '');
    DateTime? selectedReturnDate = tool.returnDate;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleDatePicker() async {
              final DateTime? picked = await showDatePicker(
                context: dialogContext,
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (picked != null &&
                  picked != selectedReturnDate &&
                  dialogContext.mounted) {
                setDialogState(() {
                  selectedReturnDate = picked;
                });
              }
            }

            // THIS ENTIRE handleBorrowReturn method and the AlertDialog below WILL BE REPLACED
            Future<void> handleBorrowReturn() async {
              final String borrowerName = borrowerNameController.text.trim();
              // If tool is NOT borrowed (i.e., we are borrowing it for the first time via FAB)
              if (!tool.isBorrowed) {
                if (borrowerName.isEmpty || selectedReturnDate == null) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please enter borrower name and select return date.'),
                      ),
                    );
                  }
                  return;
                }
                // Create new borrow entry
                final newHistoryId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                final newHistory = BorrowHistory(
                  id: newHistoryId,
                  borrowerId:
                      newHistoryId, // Or a more appropriate ID for the borrower
                  borrowerName: borrowerName,
                  borrowerPhone: borrowerPhoneController.text.trim(),
                  borrowerEmail: borrowerEmailController.text.trim().isEmpty
                      ? null
                      : borrowerEmailController.text.trim(),
                  borrowDate: DateTime.now(),
                  dueDate: selectedReturnDate!,
                  notes: notesController.text.trim(),
                );
                tool.borrowHistory.add(newHistory);
                tool.isBorrowed = true;
                tool.borrowedBy = borrowerName;
                tool.borrowerPhone = borrowerPhoneController.text.trim();
                tool.borrowerEmail = borrowerEmailController.text.trim().isEmpty
                    ? null
                    : borrowerEmailController.text.trim();
                tool.returnDate = selectedReturnDate;
                tool.notes = notesController.text.trim();
                await NotificationService().scheduleReturnReminder(tool);
              } else {
                // Tool IS borrowed (i.e., we are returning it via onTap from dashboard list)
                final history = tool.borrowHistory
                    .lastWhere((h) => h.returnDate == null, orElse: () {
                  return BorrowHistory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      borrowerId: 'fallback',
                      borrowerName: tool.borrowedBy ?? 'Unknown',
                      borrowDate:
                          tool.returnDate?.subtract(Duration(days: 1)) ??
                              DateTime.now(),
                      dueDate: tool.returnDate ?? DateTime.now());
                });
                final updatedHistory = BorrowHistory(
                  id: history.id,
                  borrowerId: history.borrowerId,
                  borrowerName: history.borrowerName,
                  borrowerPhone: history.borrowerPhone,
                  borrowerEmail: history.borrowerEmail,
                  borrowDate: history.borrowDate,
                  dueDate: history.dueDate,
                  returnDate: DateTime.now(),
                  notes: notesController.text.trim(),
                );
                await dbHelper.updateBorrowHistory(updatedHistory, tool.id);
                final historyIndex = tool.borrowHistory.indexOf(history);
                if (historyIndex != -1) {
                  tool.borrowHistory[historyIndex] = updatedHistory;
                } else {
                  tool.borrowHistory.add(updatedHistory);
                }
                tool.isBorrowed = false;
                String? oldBorrowedBy = tool.borrowedBy;
                tool.borrowedBy = null;
                tool.borrowerPhone = null;
                tool.borrowerEmail = null;
                tool.returnDate = null;
                await NotificationService().cancelToolNotifications(tool);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text(
                          'Tool "${tool.name}" marked as returned by ${oldBorrowedBy ?? 'N/A'}.')));
                }
              }

              await dbHelper.updateTool(tool);
              _loadBorrowedTools(); // Refresh the dashboard
              if (dialogContext.mounted) {
                Navigator.of(dialogContext)
                    .pop(); // Close the borrow/return dialog
                // No need to navigate back to dashboard, we are already on it or returning to it.
              }
            }

            void showBorrowHistory() {
              showDialog(
                context: dialogContext,
                builder: (BuildContext historyContext) {
                  return AlertDialog(
                    title: Text('${tool.name} - Borrow History'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: tool.borrowHistory.map((history) {
                          return Card(
                            child: ListTile(
                              title: Text(history.borrowerName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                        onPressed: () => Navigator.of(historyContext).pop(),
                      ),
                    ],
                  );
                },
              );
            }

            return AlertDialog(
              title: Text(tool.isBorrowed
                  ? 'Return Tool: ${tool.name}'
                  : 'Borrow Tool: ${tool.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (tool.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.file(File(tool.imagePath!),
                            height: 100, fit: BoxFit.cover),
                      ),
                    Text('Tool: ${tool.name}'),
                    // Fields for BORROWING an available tool
                    if (!tool.isBorrowed) ...[
                      TextField(
                        controller: borrowerNameController,
                        decoration: const InputDecoration(
                          labelText: "Borrower Name",
                          hintText: "Enter borrower's name",
                        ),
                        autofocus: true,
                      ),
                      TextField(
                        controller: borrowerPhoneController,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          hintText: "Enter borrower's phone",
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      TextField(
                        controller: borrowerEmailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "Enter borrower's email",
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedReturnDate == null
                                ? 'Select return date'
                                : 'Return by: ${DateFormat.yMd().format(selectedReturnDate!)}',
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: handleDatePicker,
                          ),
                        ],
                      ),
                    ],
                    // Fields for RETURNING a borrowed tool (or viewing details)
                    if (tool.isBorrowed) ...[
                      Text(
                          'Currently borrowed by: ${tool.borrowedBy ?? 'Unknown'}'),
                      if (tool.borrowerPhone != null)
                        Text('Phone: ${tool.borrowerPhone}'),
                      if (tool.borrowerEmail != null)
                        Text('Email: ${tool.borrowerEmail}'),
                      if (tool.returnDate != null)
                        Text(
                            'Return date: ${DateFormat.yMd().format(tool.returnDate!)}'),
                    ],
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText:
                            tool.isBorrowed ? "Return Notes" : "Borrow Notes",
                        hintText: tool.isBorrowed
                            ? "Add any notes about the return"
                            : "Add any notes about the borrowing",
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('History'),
                          onPressed: showBorrowHistory,
                        ),
                      ],
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
                  onPressed: handleBorrowReturn,
                  child: Text(tool.isBorrowed
                      ? 'Mark as Returned'
                      : 'Mark as Borrowed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // New method to show a dialog for selecting an available tool to borrow
  void _showSelectToolToBorrowDialog() async {
    List<Tool> availableTools = await dbHelper.getAvailableTools();

    if (!mounted) return;

    if (availableTools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No tools currently available to borrow.')),
      );
      return;
    }

    Tool? selectedToolForBorrowing;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Tool to Borrow'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTools.length,
              itemBuilder: (context, index) {
                final tool = availableTools[index];
                return ListTile(
                  leading: tool.imagePath != null &&
                          File(tool.imagePath!).existsSync()
                      ? Image.file(File(tool.imagePath!),
                          width: 40, height: 40, fit: BoxFit.cover)
                      : const Icon(Icons.construction, size: 40),
                  title: Text(tool.name),
                  subtitle: Text(tool.brand ?? 'N/A'),
                  onTap: () {
                    selectedToolForBorrowing = tool;
                    Navigator.of(dialogContext)
                        .pop(); // Close this selection dialog
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    ).then((_) {
      // After the selection dialog is closed
      if (selectedToolForBorrowing != null) {
        // Now open the standard borrow/return dialog for the selected tool
        _showBorrowReturnDialog(selectedToolForBorrowing!);
      }
    });
  }

  void _deleteTool(Tool tool) {
    // Deleting a tool should probably be done from the main ToolsPage for safety.
    // If allowed from dashboard, it implies deleting a borrowed tool directly.
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        Future<void> handleDelete() async {
          final String toolId = tool.id;
          await dbHelper.deleteTool(toolId);
          _loadBorrowedTools(); // Refresh dashboard
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text('"${tool.name}" deleted.')),
            );
          }
        }

        return AlertDialog(
          title: const Text('Delete Tool'),
          content: Text(
              'Are you sure you want to delete "${tool.name}"? This is a borrowed tool. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
                onPressed: handleDelete,
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dueSoonTools = _getDueSoonTools();
    final regularTools = _getRegularTools();

    return Scaffold(
      key: _scaffoldKey, // Added key for Drawer
      appBar: AppBar(
        title: const Text('Borrowed Tools Dashboard'), // Updated title
        leading: IconButton(
          // Added hamburger icon
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        // Added Drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue, // Or your app's primary color
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _loadBorrowedTools(); // Refresh the list of tools
              },
            ),
            ListTile(
              leading: const Icon(Icons.construction),
              title: const Text('All Tools'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const ToolsPage()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _borrowedTools.isEmpty // Check _borrowedTools
                ? const Center(
                    child: Text(
                        'No tools currently borrowed out.')) // Updated message
                : ListView(
                    children: [
                      if (dueSoonTools.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.amber.shade50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Due Soon (Borrowed)',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ...dueSoonTools
                                  .map((tool) => _buildToolTile(tool)),
                            ],
                          ),
                        ),
                        const Divider(thickness: 2),
                      ],
                      if (regularTools.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Other Borrowed Tools',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        ...regularTools.map((tool) => _buildToolTile(tool)),
                      ]
                    ],
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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'borrow_tool_dashboard_page',
        onPressed:
            _showSelectToolToBorrowDialog, // Changed to call the new dialog
        tooltip: 'Borrow Tool',
        child: const Icon(Icons.add_shopping_cart),
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
                child: Image.file(
                  File(tool.imagePath!),
                  fit: BoxFit.cover,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return child;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.construction, size: 40);
                  },
                ),
              ),
            )
          : const Icon(Icons.construction, size: 40),
      title: Text(tool.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
          if (tool.brand != null && tool.brand!.isNotEmpty) // Display brand
            Text('Brand: ${tool.brand}'),
          if (tool.borrowedBy != null) Text('Borrowed by: ${tool.borrowedBy}'),
          if (tool.category != null)
            Text(
              'Category: ${tool.category}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.handshake_outlined,
            color: statusColor,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
            onPressed: () => _deleteTool(tool),
            tooltip: 'Delete Tool',
          ),
        ],
      ),
      onTap: () => _showBorrowReturnDialog(tool),
      onLongPress: () => _deleteTool(tool),
    );
  }
}
