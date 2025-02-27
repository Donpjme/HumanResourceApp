// tax_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tax_rule.dart';
import '../services/tax_service.dart';

class TaxManagementScreen extends StatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTaxRules();
  }

  Future<void> _loadTaxRules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Store the service before the async gap
      final taxService = Provider.of<TaxService>(context, listen: false);
      await taxService.loadTaxRules();
    } catch (e) {
      if (mounted) {
        // Store the scaffold messenger before showing the snackbar
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

  void _showAddEditTaxRuleDialog([TaxRule? taxRule]) {
    // Store the context before showing the dialog
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => TaxRuleDialog(taxRule: taxRule),
    ).then((_) {
      if (mounted) {
        _loadTaxRules();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Management')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<TaxService>(
                builder: (context, taxService, child) {
                  final taxRules = taxService.taxRules;

                  if (taxRules.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tax rules found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditTaxRuleDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Tax Rule'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tax Brackets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure progressive tax rates based on income ranges.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: taxRules.length,
                            itemBuilder: (context, index) {
                              final taxRule = taxRules[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    taxRule.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Income Range: \$${taxRule.minIncome.toStringAsFixed(2)} - \$${taxRule.maxIncome == 1000000000 ? '∞' : taxRule.maxIncome.toStringAsFixed(2)}',
                                      ),
                                      Text(
                                        'Tax Rate: ${taxRule.rate.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: taxRule.isActive,
                                        onChanged: (value) async {
                                          // Store service and scaffold messenger before async gap
                                          final service = taxService;
                                          final scaffoldMessenger =
                                              ScaffoldMessenger.of(context);

                                          try {
                                            final updatedRule = TaxRule(
                                              id: taxRule.id,
                                              name: taxRule.name,
                                              minIncome: taxRule.minIncome,
                                              maxIncome: taxRule.maxIncome,
                                              rate: taxRule.rate,
                                              isActive: value,
                                              createdAt: taxRule.createdAt,
                                              lastModifiedAt: DateTime.now(),
                                            );

                                            await service.updateTaxRule(
                                              taxRule.id,
                                              updatedRule,
                                            );
                                          } catch (e) {
                                            if (mounted) {
                                              scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error: ${e.toString()}',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed:
                                            () => _showAddEditTaxRuleDialog(
                                              taxRule,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed:
                                            () => _showDeleteTaxRuleDialog(
                                              taxRule,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTaxRuleDialog(),
        tooltip: 'Add Tax Rule',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteTaxRuleDialog(TaxRule taxRule) {
    // Store context before dialog
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Tax Rule'),
            content: Text('Are you sure you want to delete "${taxRule.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Store service and scaffold messenger before async gap and dialog pop
                  final taxService = Provider.of<TaxService>(
                    currentContext,
                    listen: false,
                  );
                  final scaffoldMessenger = ScaffoldMessenger.of(
                    currentContext,
                  );

                  Navigator.pop(dialogContext);
                  try {
                    await taxService.deleteTaxRule(taxRule.id);
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Tax rule deleted successfully'),
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
        _loadTaxRules();
      }
    });
  }
}

class TaxRuleDialog extends StatefulWidget {
  final TaxRule? taxRule;

  const TaxRuleDialog({super.key, this.taxRule});

  @override
  State<TaxRuleDialog> createState() => _TaxRuleDialogState();
}

class _TaxRuleDialogState extends State<TaxRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minIncomeController = TextEditingController();
  final _maxIncomeController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.taxRule != null) {
      _nameController.text = widget.taxRule!.name;
      _minIncomeController.text = widget.taxRule!.minIncome.toString();

      // Handle "unlimited" max income
      if (widget.taxRule!.maxIncome == 1000000000) {
        _maxIncomeController.text = '';
      } else {
        _maxIncomeController.text = widget.taxRule!.maxIncome.toString();
      }

      _rateController.text = widget.taxRule!.rate.toString();
      _isActive = widget.taxRule!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minIncomeController.dispose();
    _maxIncomeController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveTaxRule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Store necessary references before async gap
    final taxService = Provider.of<TaxService>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final name = _nameController.text;
      final minIncome = double.parse(_minIncomeController.text);
      final maxIncome =
          _maxIncomeController.text.isEmpty
              ? 1000000000.0 // Use a very large number for "unlimited"
              : double.parse(_maxIncomeController.text);
      final rate = double.parse(_rateController.text);

      if (widget.taxRule == null) {
        // Create new tax rule
        final newTaxRule = TaxRule(
          name: name,
          minIncome: minIncome,
          maxIncome: maxIncome,
          rate: rate,
          isActive: _isActive,
        );

        await taxService.addTaxRule(newTaxRule);
      } else {
        // Update existing tax rule
        final updatedTaxRule = TaxRule(
          id: widget.taxRule!.id,
          name: name,
          minIncome: minIncome,
          maxIncome: maxIncome,
          rate: rate,
          isActive: _isActive,
          createdAt: widget.taxRule!.createdAt,
          lastModifiedAt: DateTime.now(),
        );

        await taxService.updateTaxRule(widget.taxRule!.id, updatedTaxRule);
      }

      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Tax rule saved successfully'),
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
      title: Text('${widget.taxRule == null ? 'Add' : 'Edit'} Tax Rule'),
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
                  hintText: 'e.g., Basic Rate, Higher Rate',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Income',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter minimum income';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Income (leave empty for unlimited)',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final maxIncome = double.tryParse(value);
                    if (maxIncome == null) {
                      return 'Please enter a valid number';
                    }

                    final minIncome =
                        double.tryParse(_minIncomeController.text) ?? 0;
                    if (maxIncome <= minIncome) {
                      return 'Max income must be greater than min income';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Tax Rate',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tax rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null) {
                    return 'Please enter a valid number';
                  }
                  if (rate < 0 || rate > 100) {
                    return 'Rate must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text(
                  'Inactive rules will not be used in calculations',
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
          onPressed: _isLoading ? null : _saveTaxRule,
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
