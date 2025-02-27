import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/employee_service.dart';

class EmployeeDirectory extends StatefulWidget {
  // ignore: use_super_parameters
  const EmployeeDirectory({Key? key}) : super(key: key);

  @override
  State<EmployeeDirectory> createState() => _EmployeeDirectoryState();
}

class _EmployeeDirectoryState extends State<EmployeeDirectory> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/add-employee');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<EmployeeService>(
              builder: (context, employeeService, child) {
                final employees =
                    employeeService.employees.where((employee) {
                      final fullName =
                          '${employee.firstname} ${employee.lastname}'
                              .toLowerCase();
                      return fullName.contains(searchQuery) ||
                          employee.position.toLowerCase().contains(searchQuery);
                    }).toList();

                if (employees.isEmpty) {
                  return const Center(child: Text('No employees found'));
                }

                return ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            '${employee.firstname[0]}${employee.lastname[0]}',
                          ),
                        ),
                        title: Text(
                          '${employee.firstname} ${employee.lastname}',
                        ),
                        subtitle: Text(employee.position),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/edit-employee',
                                  arguments: employee,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Delete Employee'),
                                        content: const Text(
                                          'Are you sure you want to delete this employee?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              employeeService.deleteEmployee(
                                                employee.id,
                                              );
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/edit-employee',
                            arguments: employee,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-employee');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
