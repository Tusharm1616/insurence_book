import 'package:intl/intl.dart';

void main() {
  try {
    final format = NumberFormat.decimalPattern('en_IN');
    print(format.format(1000.0));
  } catch (e) {
    print('ERROR: $e');
  }
}
