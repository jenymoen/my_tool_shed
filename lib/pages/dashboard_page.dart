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

  @override
  void initState() {
    super.initState();
    _loadTools(); // Loads tools when the widget is initialized
  }

  // --- SharePreferences Logic ---
  Future<void> _loadTools() async {
    final prefs = await SharedPreferences.getInstance();
    final String? toolsString = prefs.getString(_toolskey);
    if (toolsString != null) {
      final List<dynamic> toolsJson = jsonDecode(toolsString) as List<dynamic>;
      setState(() {
        _tools.clear();
        _tools.addAll(
          toolsJson.map((json) => Tool.fromJson(json as Map<String, dynamic>)),
        );
      });
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
      builder: (BuildContext context) {
        // Use StatefulBuilder to update dialog content (e.g., image preview)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Tool'),
              content: SingleChildScrollView(
                // In case content overflows
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
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.image_search),
                      label: const Text('Select Image'),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          // Copy image to app directory and update dialog state
                          final Directory appDir =
                              await getApplicationDocumentsDirectory();
                          final String fileName = p.basename(image.path);
                          final String newPath = p.join(appDir.path, fileName);
                          final File newImageFile = await File(
                            image.path,
                          ).copy(newPath);

                          setDialogState(() {
                            tempImagePath = newImageFile.path;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
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
                      _saveTools();
                      Navigator.of(context).pop();
                    }
                  },
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
      builder: (BuildContext context) {
        // Use a StatefulWidget builder for the dialog to manage the date picker state
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null &&
                                picked != selectedReturnDate) {
                              setDialogState(() {
                                //update dialog state for datepicker
                                selectedReturnDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  if (tool.isBorrowed) ...[
                    Text(
                      'Currently borrowed by: ${tool.borrowedBy ?? 'Unknown'}',
                    ),
                    if (tool.isBorrowed && tool.returnDate != null)
                      Text(
                        'Return date: ${DateFormat.yMd().format(tool.returnDate!)}',
                      ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    tool.isBorrowed ? 'Mark as returned' : 'Mark as Borrowed',
                  ),
                  onPressed: () {
                    final String borrowerName = borrowerController.text.trim();
                    // Validation: Require borrower name and date if borrowing
                    if (!tool.isBorrowed &&
                        (borrowerName.isEmpty || selectedReturnDate == null)) {
                      //Optionally show an error message here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter borrower name and select return date.',
                          ),
                        ),
                      );
                      return; // Prevent closing dialog if validation fails
                    }
                    setState(() {
                      final toolIndex = _tools.indexWhere(
                        (t) => t.id == tool.id,
                      );
                      if (toolIndex != -1) {
                        if (tool.isBorrowed) {
                          _tools[toolIndex].isBorrowed = false;
                          _tools[toolIndex].borrowedBy = null;
                          _tools[toolIndex].returnDate = null;
                        } else {
                          _tools[toolIndex].isBorrowed = true;
                          _tools[toolIndex].borrowedBy = borrowerName;
                          _tools[toolIndex].returnDate = selectedReturnDate;
                        }
                      }
                    });
                    _saveTools();
                    Navigator.of(context).pop();
                  },
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tool'),
          content: Text(
            'Are you sure you want to delete "${tool.name}"? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _tools.removeWhere((t) => t.id == tool.id);
                });
                _saveTools();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${tool.name}" deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tool Shed - Dashboard')),
      body:
          _tools.isEmpty
              ? const Center(child: Text('No tools yet. Add some!'))
              : ListView.builder(
                itemCount: _tools.length,
                itemBuilder: (context, index) {
                  final tool = _tools[index];
                  return ListTile(
                    leading:
                        tool.imagePath != null &&
                                File(tool.imagePath!).existsSync()
                            ? SizedBox(
                              width: 50,
                              height: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(
                                  File(tool.imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                            : const Icon(Icons.construction, size: 40),
                    title: Text(tool.name),
                    subtitle:
                        tool.isBorrowed
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
