import 'package:flutter/material.dart';
import '../widgets/drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HRM Dashboard'), elevation: 2),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to HR Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                  context,
                  'Employees',
                  Icons.people,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/employee-directory'),
                ),
                _buildDashboardCard(
                  context,
                  'Attendance',
                  Icons.access_time,
                  Colors.green,
                  () => Navigator.pushNamed(context, '/attendance'),
                ),
                _buildDashboardCard(
                  context,
                  'Leave Management',
                  Icons.event_note,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/leave'),
                ),
                _buildDashboardCard(
                  context,
                  'Payroll',
                  Icons.monetization_on,
                  Colors.purple,
                  () => Navigator.pushNamed(context, '/payroll'),
                ),
                _buildDashboardCard(
                  context,
                  'Reports',
                  Icons.analytics,
                  Colors.teal,
                  () => Navigator.pushNamed(context, '/attendance-reports'),
                ),
                _buildDashboardCard(
                  context,
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings functionality coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'System Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('HR Management System v1.0.0'),
                    Text(
                      'Current Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    ),
                    const SizedBox(height: 8),
                    const Text('Developed by Your Company Name'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
