import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/firestore_service.dart';
import 'package:my_tool_shed/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:my_tool_shed/pages/dashboard_page.dart'; // For drawer navigation
import 'package:my_tool_shed/services/auth_service.dart'; // Added for logout
import 'package:my_tool_shed/pages/login_page.dart'; // Added for navigation after logout
import 'package:my_tool_shed/pages/profile_page.dart'; // Added for ProfilePage navigation
import 'package:my_tool_shed/pages/settings_page.dart'; // Added for SettingsPage navigation
import 'package:my_tool_shed/widgets/language_selector.dart'; // Added for LanguageSelector
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added for AppLocalizations

class ToolsPage extends StatefulWidget {
  final Function(Locale) onLocaleChanged;

  const ToolsPage({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final FirestoreService _firestoreService = FirestoreService();
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
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
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
                  id: '',
                  name: name,
                  imagePath: tempImagePath,
                  brand: _selectedBrand,
                );
                try {
                  await _firestoreService.addTool(newTool);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('\\"${newTool.name}\\" added successfully.')),
                  );
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Failed to add tool: $e')),
                    );
                  }
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
                      SnackBar(content: Text('Error processing image: $e')),
                    );
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
                      SnackBar(content: Text('Error processing image: $e')),
                    );
                  }
                }
              }
            }

            Future<void> handleUpdateToolDetails() async {
              final String name = nameController.text.trim();
              if (name.isNotEmpty) {
                final updatedTool = Tool(
                  id: tool.id,
                  name: name,
                  imagePath: tempImagePath,
                  brand: currentSelectedBrand,
                  isBorrowed: tool.isBorrowed,
                  returnDate: tool.returnDate,
                  borrowedBy: tool.borrowedBy,
                  borrowHistory: tool.borrowHistory,
                  borrowerPhone: tool.borrowerPhone,
                  borrowerEmail: tool.borrowerEmail,
                  notes: tool.notes,
                  qrCode: tool.qrCode,
                  category: tool.category,
                );
                try {
                  await _firestoreService.updateTool(updatedTool);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '\\"${updatedTool.name}\\" updated successfully.')),
                  );
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Failed to update tool: $e')),
                    );
                  }
                }
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
                Tool toolToUpdate = Tool(
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
                  notes: tool.notes,
                  qrCode: tool.qrCode,
                  category: tool.category,
                );

                if (toolToUpdate.isBorrowed) {
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
                      notes: notesController.text.trim(),
                    );
                    await _firestoreService.updateBorrowHistory(
                        toolToUpdate.id, updatedHistoryEntry);
                  } else {
                    final newHistoryEntry = BorrowHistory(
                      id: '',
                      borrowerId:
                          _firestoreService.currentUser?.uid ?? 'system_return',
                      borrowerName: toolToUpdate.borrowedBy ?? "Unknown",
                      borrowDate: toolToUpdate.returnDate
                              ?.subtract(const Duration(days: 1)) ??
                          DateTime.now().subtract(const Duration(days: 1)),
                      dueDate: toolToUpdate.returnDate ?? DateTime.now(),
                      returnDate: DateTime.now(),
                      notes: notesController.text.trim(),
                    );
                    await _firestoreService.addBorrowHistory(
                        toolToUpdate.id, newHistoryEntry);
                  }

                  toolToUpdate.isBorrowed = false;
                  toolToUpdate.borrowedBy = null;
                  toolToUpdate.borrowerPhone = null;
                  toolToUpdate.borrowerEmail = null;
                  toolToUpdate.returnDate = null;
                  await NotificationService()
                      .cancelToolNotifications(toolToUpdate);
                } else {
                  final newHistoryEntry = BorrowHistory(
                    id: '',
                    borrowerId:
                        _firestoreService.currentUser?.uid ?? 'borrower_action',
                    borrowerName: borrowerName,
                    borrowerPhone: borrowerPhoneController.text.trim(),
                    borrowerEmail: borrowerEmailController.text.trim().isEmpty
                        ? null
                        : borrowerEmailController.text.trim(),
                    borrowDate: DateTime.now(),
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
                  await NotificationService()
                      .scheduleReturnReminder(toolToUpdate);
                }

                await _firestoreService.updateTool(toolToUpdate);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Tool "${toolToUpdate.name}" ${toolToUpdate.isBorrowed ? "borrowed" : "returned"}.')),
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text('Error updating tool status: $e')));
                }
              }
            }

            void showBorrowHistoryDialog() async {
              List<BorrowHistory> historyToShow =
                  await _firestoreService.getBorrowHistoryStream(tool.id).first;

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
                        decoration: InputDecoration(
                            labelText: tool.isBorrowed
                                ? "Return Notes"
                                : "Borrow Notes",
                            hintText: tool.isBorrowed
                                ? "Add any notes about the return"
                                : "Add any notes about borrowing"),
                        maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                              icon: const Icon(Icons.history),
                              label: const Text('History'),
                              onPressed: showBorrowHistoryDialog)
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
                        ? 'Mark as Returned'
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
          try {
            await _firestoreService.deleteAllBorrowHistoryForTool(tool.id);
            await _firestoreService.deleteTool(tool.id);

            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('"${tool.name}" deleted successfully.')));
          } catch (e) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete tool: $e')),
              );
            }
          }
        }

        return AlertDialog(
          title: const Text('Delete Tool'),
          content: Text(
              'Are you sure you want to delete "${tool.name}"? This will also delete its borrow history and cannot be undone.'),
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
          IconButton(
            icon: Icon(tool.isBorrowed ? Icons.undo : Icons.redo_outlined),
            color: statusColor,
            tooltip: tool.isBorrowed ? 'Return Tool' : 'Borrow Tool',
            onPressed: () => _showBorrowReturnDialog(tool),
          ),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteTool(tool),
              tooltip: 'Delete Tool'),
        ],
      ),
      onTap: () {
        _showEditToolDetailsDialog(tool);
      },
      onLongPress: () => _showBorrowReturnDialog(tool),
    );
  }

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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: Text(l10n.allTools),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
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
        title: Text(AppLocalizations.of(context)!.allTools),
        leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Tool>>(
              stream: _firestoreService.getToolsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!.noToolsYet));
                }
                final tools = snapshot.data!;
                return ListView.builder(
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    return _buildToolTile(tools[index]);
                  },
                );
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
