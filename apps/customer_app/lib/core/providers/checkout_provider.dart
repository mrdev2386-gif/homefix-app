import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../models/cart_item.dart';

class CheckoutProvider with ChangeNotifier {
  Address? _selectedAddress;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<CartItem> _items = [];
  // NEW: Selected technician for direct booking flow
  String? _selectedTechnicianId;
  String? _selectedTechnicianName;
  
  Address? get selectedAddress => _selectedAddress;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedTimeSlot => _selectedTimeSlot;
  List<CartItem> get items => _items;
  String? get selectedTechnicianId => _selectedTechnicianId;
  String? get selectedTechnicianName => _selectedTechnicianName;
  bool get hasSelectedTechnician => _selectedTechnicianId != null;

  void setAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void setDateTime(DateTime date, String slot) {
    _selectedDate = date;
    _selectedTimeSlot = slot;
    notifyListeners();
  }

  void setItems(List<CartItem> items) {
    _items = items;
    if (items.isNotEmpty && items.first.technicianId != null && items.first.technicianId!.isNotEmpty) {
      _selectedTechnicianId = items.first.technicianId;
    }
    notifyListeners();
  }

  /// Set selected technician for direct booking (new flow)
  void setSelectedTechnician(String technicianId, String technicianName) {
    _selectedTechnicianId = technicianId;
    _selectedTechnicianName = technicianName;
    notifyListeners();
  }

  void clear() {
    _selectedAddress = null;
    _selectedDate = null;
    _selectedTimeSlot = null;
    _items = [];
    _selectedTechnicianId = null;
    _selectedTechnicianName = null;
    notifyListeners();
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get taxes => subtotal * 0.05; // 5% GST
  double get grandTotal => subtotal + taxes;
}
