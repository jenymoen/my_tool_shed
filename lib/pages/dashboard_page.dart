import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
// import 'package:my_tool_shed/pages/qr_scanner_page.dart';
import 'package:my_tool_shed/services/notification_service.dart';
// import 'package:my_tool_shed/services/qr_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final List<Tool> _tools = [];
  static const String _toolskey = 'tools_list'; //Key for SharedPreferences
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Helper method to get tools that are due soon or need maintenance
  List<Tool> _getDueSoonTools() {
    final now = DateTime.now();
    return _tools.where((tool) {
      if (tool.isBorrowed && tool.returnDate != null) {
        final daysUntilDue = tool.returnDate!.difference(now).inDays;
        return daysUntilDue <= 7; // Due within a week
      }
      if (tool.maintenanceInterval > 0 && tool.lastMaintenance != null) {
        return tool.daysUntilMaintenance() <=
            7; // Maintenance due within a week
      }
      return false;
    }).toList()
      ..sort((a, b) {
        final aDate = a.isBorrowed
            ? a.returnDate!
            : a.lastMaintenance!.add(Duration(days: a.maintenanceInterval));
        final bDate = b.isBorrowed
            ? b.returnDate!
            : b.lastMaintenance!.add(Duration(days: b.maintenanceInterval));
        return aDate.compareTo(bDate);
      });
  }

  // Helper method to get regular tools (not due soon)
  List<Tool> _getRegularTools() {
    final dueSoonTools = _getDueSoonTools();
    return _tools.where((tool) => !dueSoonTools.contains(tool)).toList();
  }

  // Helper method to get status text and color for a tool
  (String, Color) _getToolStatus(Tool tool, BuildContext context) {
    final now = DateTime.now();
    if (tool.isBorrowed && tool.returnDate != null) {
      final daysUntilDue = tool.returnDate!.difference(now).inDays;
      if (daysUntilDue < 0) {
        return ('Overdue by ${-daysUntilDue} days', Colors.red);
      } else if (daysUntilDue <= 7) {
        return ('Due in $daysUntilDue days', Colors.orange);
      }
    }
    if (tool.needsMaintenance()) {
      return ('Maintenance Overdue', Colors.red);
    } else if (tool.maintenanceInterval > 0 && tool.lastMaintenance != null) {
      final daysUntil = tool.daysUntilMaintenance();
      if (daysUntil <= 7) {
        return ('Maintenance due in $daysUntil days', Colors.orange);
      }
    }
    return (tool.isBorrowed ? 'Borrowed' : 'Available', Colors.green);
  }

  @override
  void initState() {
    super.initState();
    _loadTools(); // Loads tools when the widget is initilized
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      // TODO: Replace this test ad unit ID with your real ad unit ID
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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
          print('Ad failed to load: $error');
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

  // --- SharePreferences Logic ---
  Future<void> _loadTools() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final String? toolsString = prefs.getString(_toolskey);
      if (toolsString != null) {
        final List<dynamic> toolsJson =
            jsonDecode(toolsString) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _tools.clear();
          _tools.addAll(
            toolsJson
                .map((json) => Tool.fromJson(json as Map<String, dynamic>)),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTools() async {
    final prefs = await SharedPreferences.getInstance();
    final String toolsString = jsonEncode(
      _tools.map((tool) => tool.toJson()).toList(),
    );
    await prefs.setString(_toolskey, toolsString);
  }

  // Method to show the Add Tool dialog
  void _showAddToolDialog() {
    final nameController = TextEditingController();
    String? tempImagePath;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleImageSelection() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                try {
                  final Directory appDir =
                      await getApplicationDocumentsDirectory();
                  final String fileName = p.basename(image.path);
                  final String newPath = p.join(appDir.path, fileName);
                  final File newImageFile =
                      await File(image.path).copy(newPath);

                  if (dialogContext.mounted) {
                    setDialogState(() {
                      tempImagePath = newImageFile.path;
                    });
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error processing image: $e')),
                    );
                  }
                }
              }
            }

            Future<void> handleAddTool() async {
              final String name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newTool = Tool(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  imagePath: tempImagePath,
                );
                setState(() {
                  _tools.add(newTool);
                });
                await _saveTools();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              }
            }

            return AlertDialog(
              title: const Text('Add New Tool'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: "Enter tool name",
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 15),
                    if (tempImagePath != null)
                      Image.file(
                        File(tempImagePath!),
                        height: 100,
                        fit: BoxFit.cover,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (frame == null) {
                            return const SizedBox(
                              height: 100,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return child;
                        },
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.image_search),
                      label: const Text('Select Image'),
                      onPressed: handleImageSelection,
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
                  onPressed: handleAddTool,
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to show the Borrow/Return dialog
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

            Future<void> handleBorrowReturn() async {
              final String borrowerName = borrowerNameController.text.trim();
              if (!tool.isBorrowed &&
                  (borrowerName.isEmpty || selectedReturnDate == null)) {
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

              try {
                if (tool.isBorrowed) {
                  // Create history entry for the return
                  final history =
                      tool.borrowHistory.lastWhere((h) => h.returnDate == null);
                  final updatedHistory = BorrowHistory(
                    borrowerId: history.borrowerId,
                    borrowerName: history.borrowerName,
                    borrowerPhone: history.borrowerPhone,
                    borrowerEmail: history.borrowerEmail,
                    borrowDate: history.borrowDate,
                    dueDate: history.dueDate,
                    returnDate: DateTime.now(),
                    notes: notesController.text.trim(),
                  );

                  tool.borrowHistory[tool.borrowHistory.indexOf(history)] =
                      updatedHistory;
                  tool.isBorrowed = false;
                  tool.borrowedBy = null;
                  tool.borrowerPhone = null;
                  tool.borrowerEmail = null;
                  tool.returnDate = null;
                  tool.notes = null;

                  // Cancel any existing notifications
                  await NotificationService().cancelToolNotifications(tool);
                } else {
                  // Create new borrow entry
                  final newHistory = BorrowHistory(
                    borrowerId:
                        DateTime.now().millisecondsSinceEpoch.toString(),
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
                  tool.borrowerEmail =
                      borrowerEmailController.text.trim().isEmpty
                          ? null
                          : borrowerEmailController.text.trim();
                  tool.returnDate = selectedReturnDate;
                  tool.notes = notesController.text.trim();

                  // Schedule return reminder
                  await NotificationService().scheduleReturnReminder(tool);
                }

                setState(() {});
                await _saveTools();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error updating tool: $e')),
                  );
                }
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

            void showQRCode() {
              // showDialog(
              //   context: dialogContext,
              //   builder: (BuildContext qrContext) {
              //     return AlertDialog(
              //       title: Text('${tool.name} - QR Code'),
              //       content: Column(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           QRService.generateToolQRCode(tool),
              //           const SizedBox(height: 16),
              //           const Text(
              //               'Scan this code to quickly check out this tool'),
              //         ],
              //       ),
              //       actions: [
              //         TextButton(
              //           child: const Text('Close'),
              //           onPressed: () => Navigator.of(qrContext).pop(),
              //         ),
              //       ],
              //     );
              //   },
              // );
            }

            return AlertDialog(
              title: Text(tool.isBorrowed ? 'Return Tool' : 'Borrow Tool'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (tool.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.file(
                          File(tool.imagePath!),
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Text('Tool: ${tool.name}'),
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
                      decoration: const InputDecoration(
                        labelText: "Notes",
                        hintText: "Add any notes about the borrowing",
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
                        // TextButton.icon(
                        //   icon: const Icon(Icons.qr_code),
                        //   label: const Text('QR Code'),
                        //   onPressed: showQRCode,
                        // ),
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
                      ? 'Mark as returned'
                      : 'Mark as Borrowed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTool(Tool tool) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        Future<void> handleDelete() async {
          setState(() {
            _tools.removeWhere((t) => t.id == tool.id);
          });
          await _saveTools();
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
            'Are you sure you want to delete "${tool.name}"? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              onPressed: handleDelete,
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
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
      appBar: AppBar(title: const Text('My Tool Shed - Dashboard')),
      body: Column(
        children: [
          Expanded(
            child: _tools.isEmpty
                ? const Center(child: Text('No tools yet. Add some!'))
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
                                child: Text(
                                  'Due Soon',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...dueSoonTools
                                  .map((tool) => _buildToolTile(tool)),
                            ],
                          ),
                        ),
                        const Divider(thickness: 2),
                      ],
                      ...regularTools.map((tool) => _buildToolTile(tool)),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FloatingActionButton(
          //   heroTag: 'qr_scan',
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => QRScannerPage(
          //           onToolScanned: (scannedTool) {
          //             final existingTool = _tools.firstWhere(
          //               (t) => t.id == scannedTool.id,
          //               orElse: () => scannedTool,
          //             );
          //             _showBorrowReturnDialog(existingTool);
          //           },
          //         ),
          //       ),
          //     );
          //   },
          //   child: const Icon(Icons.qr_code_scanner),
          // ),
          // const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_tool',
            onPressed: _showAddToolDialog,
            tooltip: 'Add Tool',
            child: const Icon(Icons.add),
          ),
        ],
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
          if (tool.isBorrowed && tool.borrowedBy != null)
            Text('Borrowed by: ${tool.borrowedBy}'),
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
            tool.isBorrowed
                ? Icons.handshake_outlined
                : Icons.check_circle_outline,
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
