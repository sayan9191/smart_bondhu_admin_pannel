import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final dateFormat = DateFormat('d MMM yyyy');
final dateTimeFormat = DateFormat('d MMM yyyy, h:mm a');

String formatStatus(String status) => status.replaceAll('_', ' ');
