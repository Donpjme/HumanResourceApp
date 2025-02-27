import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/employee_service.dart';
import '../services/role_service.dart';
import '../models/employee.dart';
import '../models/role.dart';

class EditEmployee extends StatefulWidget {
  final Employee employee;

  // ignore: use_super_parameters
  const EditEmployee({Key? key, required this.employee}) : super(key: key);

  @override
  State<EditEmployee> createState() => _EditEmployeeState();
}

class _EditEmployeeState extends State<EditEmployee> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  Role? _selectedRole;
  DateTime? _joiningDate;

  @override
  void initState() {
    super.initState();
    _firstnameController.text = widget.employee.firstname;
    _lastnameController.text = widget.employee.lastname;
    _employeeIdController.text = widget.employee.employeeId;
    _positionController.text = widget.employee.position;
    _emailController.text = widget.employee.email;
    _phoneController.text = widget.employee.phone;

    // Find the role by ID during initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleService = Provider.of<RoleService>(context, listen: false);
      // Find the employee's role using the roleId
      try {
        _selectedRole = roleService.roles.firstWhere(
          (role) => role.id == widget.employee.roleId,
        );
      } catch (e) {
        // If role not found, use the first one if available
        if (roleService.roles.isNotEmpty) {
          _selectedRole = roleService.roles.first;
        }
        // If no roles at all, _selectedRole remains null and will be handled in the UI
      }
      setState(() {}); // Update UI with the found role
    });

    _joiningDate = widget.employee.joiningDate;
  }

  @override
  Widget build(BuildContext context) {
    final roleService = Provider.of<RoleService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(labelText: 'Employee ID'),
                enabled: false, // Employee ID should not be editable
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstnameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Role>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items:
                    roleService.roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name),
                      );
                    }).toList(),
                onChanged: (Role? value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Joining Date'),
                subtitle: Text(
                  _joiningDate != null
                      ? '${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}'
                      : 'Select a date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _joiningDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _joiningDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedRole != null &&
                      _joiningDate != null) {
                    final updatedEmployee = Employee(
                      id: widget.employee.id,
                      employeeId: _employeeIdController.text,
                      firstname: _firstnameController.text,
                      lastname: _lastnameController.text,
                      position: _positionController.text,
                      email: _emailController.text,
                      phone: _phoneController.text,
                      roleId: _selectedRole!.id, // Use roleId instead of role
                      joiningDate: _joiningDate!,
                      createdAt: widget.employee.createdAt,
                      lastModifiedAt: DateTime.now(),
                    );

                    Provider.of<EmployeeService>(
                      context,
                      listen: false,
                    ).editEmployee(widget.employee.id, updatedEmployee);

                    Navigator.pop(context);
                  } else if (_selectedRole == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a role')),
                    );
                  } else if (_joiningDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select joining date'),
                      ),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _employeeIdController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
