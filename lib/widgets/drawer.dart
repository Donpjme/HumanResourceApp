import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HR Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your workforce efficiently',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const Divider(),
          ExpansionTile(
            leading: const Icon(Icons.people),
            title: const Text('Employee Management'),
            children: [
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Employee Directory'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/employee-directory');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add Employee'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add-employee');
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Attendance Management'),
            children: [
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Clock In/Out'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/attendance');
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/attendance-reports');
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Leave Management'),
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Leaves'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/leave');
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Payroll Management'),
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Payroll'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/payroll');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('Tax Rules'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/tax-management');
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Salary Components'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/salary-components');
                },
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings functionality coming soon'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'HR Management System',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Your Company',
                children: const [
                  SizedBox(height: 16),
                  Text('A complete HR management solution for your business.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
