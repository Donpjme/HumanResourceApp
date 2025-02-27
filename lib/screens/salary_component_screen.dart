// salary_component_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/salary_component.dart';
import '../services/salary_component_service.dart';

class SalaryComponentScreen extends StatefulWidget {
  const SalaryComponentScreen({super.key});

  @override
  State<SalaryComponentScreen> createState() => _SalaryComponentScreenState();
}

class _SalaryComponentScreenState extends State<SalaryComponentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with length 2 (for Allowances and Deductions)
    _tabController = TabController(length: 2, vsync: this);
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Store service reference before async gap
      final componentService = Provider.of<SalaryComponentService>(
        context,
        listen: false,
      );
      await componentService.loadComponents();
    } catch (e) {
      if (mounted) {
        // Store scaffold messenger before showing snackbar
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddEditComponentDialog([SalaryComponent? component]) {
    // Store context before showing dialog
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => SalaryComponentDialog(component: component),
    ).then((_) {
      if (mounted) {
        _loadComponents();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Components'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Allowances'), Tab(text: 'Deductions')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildComponentList(ComponentType.allowance),
                  _buildComponentList(ComponentType.deduction),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditComponentDialog(),
        tooltip: 'Add Component',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildComponentList(ComponentType type) {
    return Consumer<SalaryComponentService>(
      builder: (context, componentService, child) {
        final components =
            componentService.components
                .where((component) => component.type == type)
                .toList();

        if (components.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == ComponentType.allowance
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${type == ComponentType.allowance ? 'allowances' : 'deductions'} found',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditComponentDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add ${type == ComponentType.allowance ? 'Allowance' : 'Deduction'}',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: components.length,
          itemBuilder: (context, index) {
            final component = components[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  component.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.isPercentage
                          ? 'Default: ${component.defaultAmount.toStringAsFixed(1)}% of basic salary'
                          : 'Default: \$${component.defaultAmount.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Taxable: ${component.isTaxable ? 'Yes' : 'No'}',
                      style: TextStyle(
                        color: component.isTaxable ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: component.isActive,
                      onChanged: (value) async {
                        // Store service and scaffold messenger references before async gap
                        final componentService =
                            Provider.of<SalaryComponentService>(
                              context,
                              listen: false,
                            );
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        try {
                          final updatedComponent = SalaryComponent(
                            id: component.id,
                            name: component.name,
                            type: component.type,
                            isTaxable: component.isTaxable,
                            defaultAmount: component.defaultAmount,
                            isPercentage: component.isPercentage,
                            isActive: value,
                            createdAt: component.createdAt,
                            lastModifiedAt: DateTime.now(),
                          );

                          await componentService.updateComponent(
                            component.id,
                            updatedComponent,
                          );

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Component updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditComponentDialog(component),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteComponentDialog(component),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteComponentDialog(SalaryComponent component) {
    // Store context before showing dialog
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Component'),
            content: Text(
              'Are you sure you want to delete "${component.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Store service and scaffold messenger references before async gap
                  final componentService = Provider.of<SalaryComponentService>(
                    currentContext,
                    listen: false,
                  );
                  final scaffoldMessenger = ScaffoldMessenger.of(
                    currentContext,
                  );

                  Navigator.pop(dialogContext);
                  try {
                    await componentService.deleteComponent(component.id);
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Component deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    ).then((_) {
      if (mounted) {
        _loadComponents();
      }
    });
  }
}

class SalaryComponentDialog extends StatefulWidget {
  final SalaryComponent? component;

  const SalaryComponentDialog({super.key, this.component});

  @override
  State<SalaryComponentDialog> createState() => _SalaryComponentDialogState();
}

class _SalaryComponentDialogState extends State<SalaryComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  ComponentType _type = ComponentType.allowance;
  bool _isTaxable = false;
  bool _isPercentage = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.component != null) {
      _nameController.text = widget.component!.name;
      _amountController.text = widget.component!.defaultAmount.toString();
      _type = widget.component!.type;
      _isTaxable = widget.component!.isTaxable;
      _isPercentage = widget.component!.isPercentage;
      _isActive = widget.component!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveComponent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Store service, navigator and scaffold messenger references before async gap
    final componentService = Provider.of<SalaryComponentService>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final name = _nameController.text;
      final amount = double.parse(_amountController.text);

      if (widget.component == null) {
        // Create new component
        final newComponent = SalaryComponent(
          name: name,
          type: _type,
          isTaxable: _isTaxable,
          defaultAmount: amount,
          isPercentage: _isPercentage,
          isActive: _isActive,
        );

        await componentService.addComponent(newComponent);
      } else {
        // Update existing component
        final updatedComponent = SalaryComponent(
          id: widget.component!.id,
          name: name,
          type: _type,
          isTaxable: _isTaxable,
          defaultAmount: amount,
          isPercentage: _isPercentage,
          isActive: _isActive,
          createdAt: widget.component!.createdAt,
          lastModifiedAt: DateTime.now(),
        );

        await componentService.updateComponent(
          widget.component!.id,
          updatedComponent,
        );
      }

      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Component saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.component == null ? 'Add' : 'Edit'} Component'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Housing Allowance, Health Insurance',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ComponentType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items:
                    ComponentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == ComponentType.allowance
                              ? 'Allowance'
                              : 'Deduction',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Default Amount',
                  prefixText: _isPercentage ? '' : '\$ ',
                  suffixText: _isPercentage ? '%' : '',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount < 0) {
                    return 'Amount cannot be negative';
                  }
                  if (_isPercentage && amount > 100) {
                    return 'Percentage cannot exceed 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Percentage Based'),
                subtitle: const Text(
                  'Amount is calculated as a percentage of basic salary',
                ),
                value: _isPercentage,
                onChanged: (value) {
                  setState(() {
                    _isPercentage = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Taxable'),
                subtitle: const Text(
                  'This component affects the taxable income calculation',
                ),
                value: _isTaxable,
                onChanged: (value) {
                  setState(() {
                    _isTaxable = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text(
                  'Inactive components will not be used in payroll generation',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveComponent,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }
}
