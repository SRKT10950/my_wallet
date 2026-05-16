import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/category.dart';

class CategoryManagerScreen extends StatelessWidget {
  const CategoryManagerScreen({super.key});

  void _showAddOrEditModal(BuildContext context, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryFormSheet(category: category),
    );
  }

  void _deleteCategory(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).deleteCategory(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final categories = provider.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Category Manager')),
      body: categories.isEmpty
          ? const Center(child: Text('No categories added yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Planned: ₹${cat.plannedAmount.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showAddOrEditModal(context, category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteCategory(context, cat.id!, cat.name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditModal(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}

class CategoryFormSheet extends StatefulWidget {
  final Category? category;
  const CategoryFormSheet({super.key, this.category});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _planController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _planController.text = widget.category!.plannedAmount.toString();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final newCat = Category(
        id: widget.category?.id,
        name: _nameController.text,
        plannedAmount: double.parse(_planController.text),
      );

      if (widget.category == null) {
        provider.addCategory(newCat);
      } else {
        provider.updateCategory(newCat);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEditing ? 'Update Category' : 'New Category', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _planController,
              decoration: const InputDecoration(labelText: 'Planned Amount', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submit,
                child: Text(isEditing ? 'Save Changes' : 'Add Category', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
