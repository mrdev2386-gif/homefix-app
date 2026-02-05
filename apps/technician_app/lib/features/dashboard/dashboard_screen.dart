import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("John Doe"),
              accountEmail: Text("Plumber"),
              currentAccountPicture: CircleAvatar(child: Text("JD")),
            ),
            ListTile(title: const Text("Earnings"), onTap: () {}),
            ListTile(title: const Text("History"), onTap: () {}),
            ListTile(title: const Text("Settings"), onTap: () {}),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Total Earnings", "\$1,250", Colors.green),
            const SizedBox(height: 16),
            _buildStatCard("Jobs Completed", "45", Colors.blue),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/jobs'),
              icon: const Icon(Icons.list),
              label: const Text("View Job Requests"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, color: color.withOpacity(0.8))),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
