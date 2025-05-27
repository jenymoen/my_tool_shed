import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/database_helper.dart';
import 'package:my_tool_shed/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:my_tool_shed/pages/dashboard_page.dart'; // For drawer navigation

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => ToolsPageState();
}

class ToolsPageState extends State<ToolsPage> {
  final List<Tool> _allTools = [];
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final dbHelper = DatabaseHelper.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Predefined list of brands (can be moved to a shared location later)
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

  @override
  void initState() {
    super.initState();
    _loadAllTools();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-5326232965412305~2242713432', // Replace with your Ad Unit ID
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
          print('Ad failed to load on ToolsPage: $error');
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

  Future<void> _loadAllTools() async {
    try {
      setState(() => _isLoading = true);
      final loadedTools = await dbHelper.getAllTools();
      if (!mounted) return;
      setState(() {
        _allTools.clear();
        _allTools.addAll(loadedTools);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to get status text and color for a tool (can be refactored)
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
    return (tool.isBorrowed ? 'Borrowed' : 'Available', Colors.green);
  }

  // Method to show the Add Tool dialog (can be refactored)
  void _showAddToolDialog() {
    final nameController = TextEditingController();
    String? tempImagePath;
    _selectedBrand = null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleImageSelection() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image =
                  await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                try {
                  final Directory appDir =
                      await getApplicationDocumentsDirectory();
                  final String fileName = p.basename(image.path);
                  final String newPath = p.join(appDir.path, fileName);
                  final File newImageFile =
                      await File(image.path).copy(newPath);
                  if (dialogContext.mounted) {
                    setDialogState(() => tempImagePath = newImageFile.path);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error processing image: $e')));
                  }
                }
              }
            }

            Future<void> handleTakePicture() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image =
                  await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                try {
                  final Directory appDir =
                      await getApplicationDocumentsDirectory();
                  final String fileName = p.basename(image.path);
                  final String newPath = p.join(appDir.path, fileName);
                  final File newImageFile =
                      await File(image.path).copy(newPath);
                  if (dialogContext.mounted) {
                    setDialogState(() => tempImagePath = newImageFile.path);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error processing image: $e')));
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
                  brand: _selectedBrand,
                );
                await dbHelper.insertTool(newTool);
                _loadAllTools(); // Refresh list
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
                        decoration:
                            const InputDecoration(hintText: "Enter tool name"),
                        autofocus: true),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Brand'),
                      value: _selectedBrand,
                      hint: const Text('Select brand (optional)'),
                      items: _brandOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) =>
                          setDialogState(() => _selectedBrand = newValue),
                    ),
                    const SizedBox(height: 15),
                    if (tempImagePath != null)
                      Image.file(File(tempImagePath!),
                          height: 100,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) =>
                              frame == null
                                  ? const SizedBox(
                                      height: 100,
                                      child: Center(
                                          child: CircularProgressIndicator()))
                                  : child),
                    TextButton.icon(
                        icon: const Icon(Icons.image_search),
                        label: const Text('Select Image'),
                        onPressed: handleImageSelection),
                    TextButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Picture'),
                        onPressed: handleTakePicture),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop()),
                TextButton(onPressed: handleAddTool, child: const Text('Add')),
              ],
            );
          },
        );
      },
    );
  }

  // New method to show Edit Tool Details Dialog
  void _showEditToolDetailsDialog(Tool tool) {
    final nameController = TextEditingController(text: tool.name);
    String? tempImagePath = tool.imagePath;
    String? currentSelectedBrand = tool.brand;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleImageSelection() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image =
                  await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                try {
                  final Directory appDir =
                      await getApplicationDocumentsDirectory();
                  final String fileName = p.basename(image.path);
                  final String newPath = p.join(appDir.path, fileName);
                  final File newImageFile =
                      await File(image.path).copy(newPath);
                  if (dialogContext.mounted) {
                    setDialogState(() => tempImagePath = newImageFile.path);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error processing image: $e')));
                  }
                }
              }
            }

            Future<void> handleTakePicture() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image =
                  await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                try {
                  final Directory appDir =
                      await getApplicationDocumentsDirectory();
                  final String fileName = p.basename(image.path);
                  final String newPath = p.join(appDir.path, fileName);
                  final File newImageFile =
                      await File(image.path).copy(newPath);
                  if (dialogContext.mounted) {
                    setDialogState(() => tempImagePath = newImageFile.path);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error processing image: $e')));
                  }
                }
              }
            }

            Future<void> handleUpdateToolDetails() async {
              final String name = nameController.text.trim();
              if (name.isNotEmpty) {
                tool.name = name;
                tool.imagePath = tempImagePath;
                tool.brand = currentSelectedBrand;

                await dbHelper.updateTool(tool);
                _loadAllTools(); // Refresh list
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              title: Text('Edit ${tool.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "Tool Name"),
                        autofocus: true),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Brand'),
                      value: currentSelectedBrand,
                      hint: const Text('Select brand (optional)'),
                      items: _brandOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) =>
                          setDialogState(() => currentSelectedBrand = newValue),
                    ),
                    const SizedBox(height: 15),
                    if (tempImagePath != null)
                      Image.file(File(tempImagePath!),
                          height: 100,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) =>
                              frame == null
                                  ? const SizedBox(
                                      height: 100,
                                      child: Center(
                                          child: CircularProgressIndicator()))
                                  : child),
                    TextButton.icon(
                        icon: const Icon(Icons.image_search),
                        label: const Text('Change Image'),
                        onPressed: handleImageSelection),
                    TextButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take New Picture'),
                        onPressed: handleTakePicture),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop()),
                TextButton(
                    onPressed: handleUpdateToolDetails,
                    child: const Text('Save Changes')),
              ],
            );
          },
        );
      },
    );
  }

  // Method to show the Borrow/Return dialog (can be refactored)
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
                  lastDate: DateTime(2101));
              if (picked != null &&
                  picked != selectedReturnDate &&
                  dialogContext.mounted) {
                setDialogState(() => selectedReturnDate = picked);
              }
            }

            Future<void> handleBorrowReturn() async {
              final String borrowerName = borrowerNameController.text.trim();
              if (!tool.isBorrowed &&
                  (borrowerName.isEmpty || selectedReturnDate == null)) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                      content: Text(
                          'Please enter borrower name and select return date.')));
                }
                return;
              }
              try {
                if (tool.isBorrowed) {
                  final history =
                      tool.borrowHistory.lastWhere((h) => h.returnDate == null);
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
                  }

                  tool.isBorrowed = false;
                  tool.borrowedBy = null;
                  tool.borrowerPhone = null;
                  tool.borrowerEmail = null;
                  tool.returnDate = null;
                  tool.notes = null;
                  await NotificationService().cancelToolNotifications(tool);
                } else {
                  final newHistoryId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  final newHistory = BorrowHistory(
                    id: newHistoryId,
                    borrowerId: newHistoryId,
                    borrowerName: borrowerName,
                    borrowerPhone: borrowerPhoneController.text.trim(),
                    borrowerEmail: borrowerEmailController.text.trim().isEmpty
                        ? null
                        : borrowerEmailController.text.trim(),
                    borrowDate: DateTime.now(),
                    dueDate: selectedReturnDate!,
                    notes: notesController.text.trim(),
                  );
                  await dbHelper.insertBorrowHistory(newHistory, tool.id);
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
                  await NotificationService().scheduleReturnReminder(tool);
                }
                await dbHelper.updateTool(tool);
                _loadAllTools(); // Refresh list
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (dialogContext.mounted)
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error updating tool: $e')));
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
                          onPressed: () => Navigator.of(historyContext).pop())
                    ],
                  );
                },
              );
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
                          child: Image.file(File(tool.imagePath!),
                              height: 100, fit: BoxFit.cover)),
                    Text('Tool: ${tool.name}'),
                    if (!tool.isBorrowed) ...[
                      TextField(
                          controller: borrowerNameController,
                          decoration: const InputDecoration(
                              labelText: "Borrower Name",
                              hintText: "Enter borrower's name"),
                          autofocus: true),
                      TextField(
                          controller: borrowerPhoneController,
                          decoration: const InputDecoration(
                              labelText: "Phone Number",
                              hintText: "Enter borrower's phone"),
                          keyboardType: TextInputType.phone),
                      TextField(
                          controller: borrowerEmailController,
                          decoration: const InputDecoration(
                              labelText: "Email",
                              hintText: "Enter borrower's email"),
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedReturnDate == null
                                ? 'Select return date'
                                : 'Return by: ${DateFormat.yMd().format(selectedReturnDate!)}'),
                            IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: handleDatePicker)
                          ]),
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
                            hintText: "Add any notes about the borrowing"),
                        maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                              icon: const Icon(Icons.history),
                              label: const Text('History'),
                              onPressed: showBorrowHistory)
                        ]),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop()),
                TextButton(
                    onPressed: handleBorrowReturn,
                    child: Text(tool.isBorrowed
                        ? 'Mark as returned'
                        : 'Mark as Borrowed')),
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
          final String toolId = tool.id;
          await dbHelper.deleteTool(toolId);
          _loadAllTools(); // Refresh list
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('"${tool.name}" deleted.')));
          }
        }

        return AlertDialog(
          title: const Text('Delete Tool'),
          content: Text(
              'Are you sure you want to delete "${tool.name}"? This cannot be undone.'),
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
          if (tool.isBorrowed && tool.borrowedBy != null)
            Text('Borrowed by: ${tool.borrowedBy}'),
          if (tool.category != null)
            Text('Category: ${tool.category}',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              tool.isBorrowed
                  ? Icons.handshake_outlined
                  : Icons.check_circle_outline,
              color: statusColor),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteTool(tool),
              tooltip: 'Delete Tool'),
        ],
      ),
      onTap: () {
        _showEditToolDetailsDialog(tool); // Always edit tool details on tap
      },
      onLongPress: () => _deleteTool(tool),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('All Tools'),
        leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text('Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24))),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DashboardPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.construction),
              title: const Text('Tools'),
              onTap: () {
                Navigator.pop(
                    context); // Close drawer (already on Tools page, effectively a refresh if _loadAllTools is called)
                _loadAllTools();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _allTools.isEmpty
                ? const Center(child: Text('No tools yet. Add some!'))
                : ListView.builder(
                    itemCount: _allTools.length,
                    itemBuilder: (context, index) {
                      return _buildToolTile(_allTools[index]);
                    },
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
        heroTag: 'add_tool_tools_page',
        onPressed: _showAddToolDialog,
        tooltip: 'Add Tool',
        child: const Icon(Icons.add),
      ),
    );
  }
}
