class ServiceCategories {
  static const List<Map<String, String>> categories = [
    {'id': 'plumbing', 'name': 'Plumbing'},
    {'id': 'electrical', 'name': 'Electrical'},
    {'id': 'carpentry', 'name': 'Carpentry'},
    {'id': 'painting', 'name': 'Painting'},
    {'id': 'cleaning', 'name': 'Cleaning'},
    {'id': 'appliance', 'name': 'Appliance Repair'},
  ];

  static String? getCategoryName(String id) {
    try {
      return categories.firstWhere((c) => c['id'] == id)['name'];
    } catch (e) {
      return null;
    }
  }
}
