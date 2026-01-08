import 'livestock_model.dart';

class CartItem {
  final String id;
  final Livestock livestock;
  int quantity;
  final String selectedWeight;
  final double selectedPrice;

  CartItem({
    required this.id,
    required this.livestock,
    this.quantity = 1,
    this.selectedWeight = '',
    this.selectedPrice = 0.0,
  });

  // Helper to get the total cost for this line item
  double get totalPrice => selectedPrice * quantity;
}
