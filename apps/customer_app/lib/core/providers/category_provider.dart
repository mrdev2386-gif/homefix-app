import 'package:flutter/material.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  String _searchQuery = '';
  bool _isLoading = true;

  List<Category> get categories => _filteredCategories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  CategoryProvider() {
    _loadCategories();
  }

  void _loadCategories() {
    _categoryService.getCategories().listen((List<Category> categories) {
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
}
