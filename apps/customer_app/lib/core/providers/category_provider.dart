import 'dart:async';
import 'package:flutter/material.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  late final CategoryService _categoryService;
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  String _searchQuery = '';
  bool _isLoading = true;
  StreamSubscription<List<Category>>? _categoriesSubscription;

  List<Category> get categories => _filteredCategories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  CategoryProvider({CategoryService? categoryService}) {
    _categoryService = categoryService ?? CategoryService();
    _loadCategories();
  }

  void _loadCategories() {
    _categoriesSubscription?.cancel();
    _categoriesSubscription = _categoryService.getCategories().listen((List<Category> categories) {
      _categories = categories;
      _applySearch();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error loading categories: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    _filteredCategories = _categoryService.searchCategories(_categories, _searchQuery);
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
