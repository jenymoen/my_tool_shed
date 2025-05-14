import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_tool_shed/models/tool.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTools(); // Loads tools when the widget is initilized
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
    final borrowerController = TextEditingController(
      text: tool.borrowedBy ?? '',
    );
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
              final String borrowerName = borrowerController.text.trim();
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
                  tool.isBorrowed = false;
                  tool.borrowedBy = null;
                  tool.returnDate = null;
                } else {
                  tool.isBorrowed = true;
                  tool.borrowedBy = borrowerName;
                  tool.returnDate = selectedReturnDate;
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

            return AlertDialog(
              title: Text(tool.isBorrowed ? 'Return Tool' : 'Borrow Tool'),
              content: Column(
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
                      controller: borrowerController,
                      decoration: const InputDecoration(
                        hintText: "Borrowed by?",
                      ),
                      autofocus: true,
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
                    if (tool.returnDate != null)
                      Text(
                          'Return date: ${DateFormat.yMd().format(tool.returnDate!)}'),
                  ],
                ],
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

    return Scaffold(
      appBar: AppBar(title: const Text('My Tool Shed - Dashboard')),
      body: _tools.isEmpty
          ? const Center(child: Text('No tools yet. Add some!'))
          : ListView.builder(
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                return ListTile(
                  leading: tool.imagePath != null &&
                          File(tool.imagePath!).existsSync()
                      ? SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              File(tool.imagePath!),
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                if (frame == null) {
                                  return const Center(
                                      child: CircularProgressIndicator());
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
                  subtitle: tool.isBorrowed
                      ? Text(
                          'Borrowed by: ${tool.borrowedBy ?? 'Unknown'}\nReturn by: ${tool.returnDate != null ? DateFormat.yMd().format(tool.returnDate!) : 'N/A'}',
                        )
                      : const Text('Available'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tool.isBorrowed
                            ? Icons.handshake_outlined
                            : Icons.check_circle_outline,
                        color: tool.isBorrowed ? Colors.orange : Colors.green,
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
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToolDialog,
        tooltip: 'Add Tool',
        child: const Icon(Icons.add),
      ),
    );
  }
}
