class ServiceItem {
  final String id;
  final String title;
  final String imagePath;
  final String category;
  final int? price;
  final int? durationMins;

  const ServiceItem({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.category,
    this.price,
    this.durationMins,
  });
  
  // Compatibility getter
  num? get basePrice => price;
}

class ServicesCatalog {
  static const List<ServiceItem> services = [
    ServiceItem(
      id: 'ac_service',
      title: 'AC Repair',
      imagePath: 'assets/services/ac.png',
      category: 'appliances',
      price: 599,
      durationMins: 60,
    ),
    ServiceItem(
      id: 'fridge',
      title: 'Fridge Repair',
      imagePath: 'assets/services/fridge.png',
      category: 'appliances',
      price: 699,
      durationMins: 60,
    ),
    ServiceItem(
      id: 'washing_machine',
      title: 'Washing Machine',
      imagePath: 'assets/services/washing_machine.png',
      category: 'appliances',
      price: 599,
      durationMins: 60,
    ),
    ServiceItem(
      id: 'ro',
      title: 'RO Service',
      imagePath: 'assets/services/ro.png',
      category: 'appliances',
      price: 499,
    ),
    ServiceItem(
      id: 'electrician',
      title: 'Electrician',
      imagePath: 'assets/services/electrician.png',
      category: 'home_repair',
      price: 299,
    ),
    ServiceItem(
      id: 'plumbing',
      title: 'Plumbing',
      imagePath: 'assets/services/plumbing.png',
      category: 'home_repair',
      price: 299,
    ),
    ServiceItem(
      id: 'cleaning',
      title: 'Full Cleaning',
      imagePath: 'assets/services/cleaning.png',
      category: 'cleaning',
      price: 999,
    ),
    ServiceItem(
      id: 'pest_control',
      title: 'Pest Control',
      imagePath: 'assets/services/pest_control.png',
      category: 'cleaning',
      price: 899,
    ),
    ServiceItem(
      id: 'microwave',
      title: 'Microwave Repair',
      imagePath: 'assets/services/microwave.png',
      category: 'appliances',
      price: 499,
    ),
    ServiceItem(
      id: 'tv',
      title: 'TV Repair',
      imagePath: 'assets/services/tv.png',
      category: 'appliances',
      price: 599,
    ),
  ];
}
