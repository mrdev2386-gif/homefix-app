import 'dart:async';
import 'package:flutter/material.dart';
import '../models/service.dart';
import '../firestore/service_catalog_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceCatalogService _serviceCatalogService = ServiceCatalogService();
  
  List<HomeService> _allServices = [];
  List<HomeService> _filteredServices = [];
  List<HomeService> get services => _filteredServices;
  String _searchQuery = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<HomeService>>? _servicesSubscription;

  ServiceProvider() {
    _fetchServices();
  }

  void _fetchServices() {
    _isLoading = true;
    notifyListeners();

    _servicesSubscription?.cancel();
    _servicesSubscription = _serviceCatalogService.getActiveServices().listen((s) {
      _allServices = s;
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      debugPrint("ServiceProvider: Error fetching services: $e");
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredServices = List.from(_allServices);
    } else {
      _filteredServices = _allServices.where((s) => 
        s.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        s.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    super.dispose();
  }
}
