import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String format(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatNullable(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }
}
