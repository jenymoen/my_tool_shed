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
import 'package:my_tool_shed/pages/community/community_page.dart'; // Added for CommunityPage
import 'package:my_tool_shed/pages/community/tool_details_page.dart'; // Added for ToolDetailsPage
// import 'package:my_tool_shed/widgets/language_selector.dart'; // Added for LanguageSelector
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added for AppLocalizations
import 'package:my_tool_shed/services/storage_service.dart';
import 'package:my_tool_shed/widgets/app_drawer.dart';
import 'package:my_tool_shed/widgets/ad_banner_widget.dart';
import 'package:my_tool_shed/utils/ad_constants.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedBrand;
  final List<String> _brandOptions = [
    'DeWalt',
    'Milwaukee',
    'Makita',
    'Bosch',
    'Ryobi',
    'Black+Decker',
    'Craftsman',
    'Husky',
    'Kobalt',
    'Ridgid',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  (String, Color) _getToolStatus(Tool tool, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    if (tool.isBorrowed && tool.returnDate != null) {
      final daysUntilDue = tool.returnDate!.difference(now).inDays;
      if (daysUntilDue < 0) {
        return (l10n.overdueBy(daysUntilDue.abs().toString()), Colors.red);
      } else if (daysUntilDue <= 7) {
        return (l10n.dueIn(daysUntilDue.toString()), Colors.orange);
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
                String? imageUrl;
                if (tempImagePath != null) {
                  try {
                    final storageService = StorageService();
                    imageUrl = await storageService.uploadToolImage(
                      File(tempImagePath!),
                      DateTime.now().millisecondsSinceEpoch.toString(),
                    );
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to upload image: $e')),
                      );
                    }
                    return;
                  }
                }

                final newTool = Tool(
                  id: '',
                  name: name,
                  imagePath: imageUrl,
                  brand: _selectedBrand,
                  ownerId: _firestoreService.currentUser?.uid ?? 'unknown',
                  ownerName: _firestoreService.currentUser?.displayName ??
                      'Unknown User',
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
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: tempImagePath!.startsWith('http') ||
                                  tempImagePath!.startsWith('https') ||
                                  tempImagePath!.startsWith('gs://')
                              ? Image.network(
                                  tempImagePath!.startsWith('gs://')
                                      ? 'https://storage.googleapis.com/${tempImagePath!.substring(5)}'
                                      : tempImagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.construction, size: 40),
                                )
                              : Image.file(
                                  File(tempImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.construction, size: 40),
                                ),
                        ),
                      ),
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
                String? imageUrl = tool.imagePath;
                if (tempImagePath != null && tempImagePath != tool.imagePath) {
                  try {
                    final storageService = StorageService();
                    // Delete old image if it exists
                    if (tool.imagePath != null) {
                      await storageService.deleteToolImage(tool.imagePath!);
                    }
                    // Upload new image
                    imageUrl = await storageService.uploadToolImage(
                      File(tempImagePath!),
                      DateTime.now().millisecondsSinceEpoch.toString(),
                    );
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to upload image: $e')),
                      );
                    }
                    return;
                  }
                }

                final updatedTool = Tool(
                  id: tool.id,
                  name: name,
                  imagePath: imageUrl,
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
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: tempImagePath!.startsWith('http') ||
                                  tempImagePath!.startsWith('https') ||
                                  tempImagePath!.startsWith('gs://')
                              ? Image.network(
                                  tempImagePath!.startsWith('gs://')
                                      ? 'https://storage.googleapis.com/${tempImagePath!.substring(5)}'
                                      : tempImagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.construction, size: 40),
                                )
                              : Image.file(
                                  File(tempImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.construction, size: 40),
                                ),
                        ),
                      ),
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
      leading: tool.imagePath != null
          ? SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    tool.imagePath!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.construction, size: 40),
                  )))
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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditToolDetailsDialog(tool),
            tooltip: 'Edit Tool',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteTool(tool),
            tooltip: 'Delete Tool',
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolDetailsPage(
              tool: tool,
              currentUserId: _firestoreService.currentUser?.uid ?? '',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(l10n.allTools),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: AppDrawer(onLocaleChanged: widget.onLocaleChanged),
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
          AdBannerWidget(
            adUnitId: AdConstants.getAdUnitId(
              AdConstants.toolsBannerAdUnitId,
              isDebug: false, // Set to true for test ads, false for production
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
