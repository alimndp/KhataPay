import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static final NumberFormat _compactCurrency =
      NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String currency(num amount) => _currencyFormat.format(amount);

  static String compactCurrency(num amount) => _compactCurrency.format(amount);

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String time(DateTime dateTime) => _timeFormat.format(dateTime);

  static String monthYear(DateTime date) => DateFormat('MMM yyyy').format(date);

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String phone(String phone) {
    if (phone.isEmpty) return 'N/A';
    return phone;
  }

  static String email(String email) {
    if (email.isEmpty) return 'N/A';
    return email;
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}