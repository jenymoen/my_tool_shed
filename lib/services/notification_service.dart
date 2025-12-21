import 'package:my_tool_shed/models/tool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_tool_shed/utils/logger.dart';

/// Service for managing in-app notifications for tool return reminders.
/// Uses SharedPreferences to track pending reminders and provides methods
/// to check for due reminders on app launch.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _reminderPrefix = 'reminder_';
  SharedPreferences? _prefs;

  /// Initialize notification service
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('NotificationService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize NotificationService', e);
    }
  }

  /// Schedule a return reminder for a tool
  /// Stores the tool ID and return date in SharedPreferences
  Future<void> scheduleReturnReminder(Tool tool) async {
    if (_prefs == null) await init();
    if (tool.returnDate == null) return;

    try {
      final key = '$_reminderPrefix${tool.id}';
      await _prefs?.setString(key, tool.returnDate!.toIso8601String());
      AppLogger.info('Scheduled return reminder for tool: ${tool.name}');
    } catch (e) {
      AppLogger.error('Failed to schedule reminder for tool: ${tool.name}', e);
    }
  }

  /// Cancel tool notifications
  Future<void> cancelToolNotifications(Tool tool) async {
    if (_prefs == null) await init();

    try {
      final key = '$_reminderPrefix${tool.id}';
      await _prefs?.remove(key);
      AppLogger.info('Cancelled reminder for tool: ${tool.name}');
    } catch (e) {
      AppLogger.error('Failed to cancel reminder for tool: ${tool.name}', e);
    }
  }

  /// Get all tools with pending return reminders that are due soon (within 3 days)
  /// or overdue. Returns a list of (toolId, returnDate) pairs.
  Future<List<(String, DateTime)>> getDueReminders() async {
    if (_prefs == null) await init();
    
    final List<(String, DateTime)> dueReminders = [];
    final now = DateTime.now();
    
    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith(_reminderPrefix)) {
          final toolId = key.substring(_reminderPrefix.length);
          final dateStr = _prefs?.getString(key);
          if (dateStr != null) {
            final returnDate = DateTime.parse(dateStr);
            final daysUntilDue = returnDate.difference(now).inDays;
            // Include if due within 3 days or overdue
            if (daysUntilDue <= 3) {
              dueReminders.add((toolId, returnDate));
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get due reminders', e);
    }
    
    return dueReminders;
  }
}
