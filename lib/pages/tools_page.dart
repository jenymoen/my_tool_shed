import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/firestore_service.dart';
// import 'package:my_tool_shed/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:my_tool_shed/pages/dashboard_page.dart'; // For drawer navigation
import 'package:my_tool_shed/services/auth_service.dart'; // Added for logout
import 'package:my_tool_shed/pages/login_page.dart'; // Added for navigation after logout
import 'package:my_tool_shed/pages/profile_page.dart'; // Added for ProfilePage navigation
import 'package:my_tool_shed/pages/settings_page.dart'; // Added for SettingsPage navigation
// import 'package:my_tool_shed/widgets/language_selector.dart'; // Added for LanguageSelector
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
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    if (tool.isBorrowed && tool.returnDate != null) {
      final daysUntilDue = tool.returnDate!.difference(now).inDays;
      if (daysUntilDue < 0) {
        return (l10n.overdueBy(daysUntilDue.abs()), Colors.red);
      } else if (daysUntilDue <= 7) {
        return (l10n.dueIn(daysUntilDue), Colors.orange);
      }
    }
    return (tool.isBorrowed ? l10n.borrowed : l10n.available, Colors.green);
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
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Error processing image')));
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
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Error processing image')));
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
                  ownerId: _firestoreService.currentUser?.uid ?? 'system',
                  ownerName:
                      _firestoreService.currentUser?.displayName ?? 'System',
                  isAvailableForCommunity: false,
                  allowedBorrowers: const [],
                  communityRating: 0.0,
                  totalCommunityRatings: 0,
                  requiresApproval: true,
                  lastMaintenanceDate: DateTime.now(),
                );
                try {
                  await _firestoreService.addTool(newTool);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              '\\"${newTool.name}\\" added successfully.')),
                    );
                  }
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
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Error processing image')));
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
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Error processing image')));
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
                  ownerId: tool.ownerId,
                  ownerName: tool.ownerName,
                  isAvailableForCommunity: tool.isAvailableForCommunity,
                  allowedBorrowers: List<String>.from(tool.allowedBorrowers),
                  communityRating: tool.communityRating,
                  totalCommunityRatings: tool.totalCommunityRatings,
                  requiresApproval: tool.requiresApproval,
                  location: tool.location,
                  condition: tool.condition,
                  lastMaintenanceDate: tool.lastMaintenanceDate,
                  maintenanceNotes: tool.maintenanceNotes,
                );
                try {
                  await _firestoreService.updateTool(updatedTool);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              '\\"${updatedTool.name}\\" updated successfully.')),
                    );
                  }
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

  void _deleteTool(Tool tool) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        Future<void> handleDelete() async {
          try {
            await _firestoreService.deleteAllBorrowHistoryForTool(tool.id);
            await _firestoreService.deleteTool(tool.id);

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                  content: Text('"${tool.name}" deleted successfully.')));
            }
          } catch (e) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(dialogContext).showSnackBar(
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
      trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _deleteTool(tool),
          tooltip: 'Delete Tool'),
      onTap: () => _showEditToolDetailsDialog(tool),
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
              final navigator = Navigator.of(context);
              await AuthService().signOut();
              if (context.mounted) {
                navigator.pushReplacement(
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
