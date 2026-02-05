import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HomeFix")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategory(context, "Cleaning", Icons.cleaning_services),
          _buildCategory(context, "Plumbing", Icons.plumbing),
          _buildCategory(context, "Electrical", Icons.electrical_services),
          _buildCategory(context, "Painting", Icons.format_paint),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to services
        },
      ),
    );
  }
}
