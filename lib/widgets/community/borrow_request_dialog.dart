import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/utils/date_formatter.dart';

class BorrowRequestDialog extends StatefulWidget {
  final Tool tool;
  final Function(DateTime startDate, DateTime endDate, String notes) onSubmit;

  const BorrowRequestDialog({
    super.key,
    required this.tool,
    required this.onSubmit,
  });

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request to Borrow ${widget.tool.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: () => _selectDate(context, true),
                        child: Text(
                          _startDate == null
                              ? 'Select Date'
                              : DateFormatter.format(_startDate!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: _startDate == null
                            ? null
                            : () => _selectDate(context, false),
                        child: Text(
                          _endDate == null
                              ? 'Select Date'
                              : DateFormatter.format(_endDate!),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional information about your request',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _startDate == null || _endDate == null
                      ? null
                      : () {
                          widget.onSubmit(
                            _startDate!,
                            _endDate!,
                            _notesController.text,
                          );
                          Navigator.pop(context);
                        },
                  child: const Text('Submit Request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
