void main() {
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+$)'),
      (match) => '${match[1]}${match[2] != null ? ',' : ''}${match[2] ?? ''}',
    );
  }
  print(_formatCurrency(100000.0));
  print(_formatCurrency(0.0));
}
