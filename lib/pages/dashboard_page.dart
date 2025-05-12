import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/tool.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final List<Tool> _tools = [];

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
                    title: Text(tool.name),
                    subtitle:
                        tool.isBorrowed
                            ? Text(
                              'Borrowed by: ${tool.borrowedBy ?? 'Unknown'}\nReturn by: ${tool.returnDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                            )
                            : const Text('Available'),
                    trailing: Icon(
                      tool.isBorrowed
                          ? Icons.handshake_outlined
                          : Icons.check_circle_outline,
                      color: tool.isBorrowed ? Colors.orange : Colors.green,
                    ),
                    onTap: () {
                      // Todo: Implement tap to view/edit tool details or mark as borrowed/returned
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Todo: Implement navigation to an AddToolPage or show amd AddToolDialog
        },
        tooltip: 'Add Tool',
        child: const Icon(Icons.add),
      ),
    );
  }
}
