import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/feedback_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoriesProvider provider;

  @override
  void initState() {
    super.initState();
    provider = CategoriesProvider(context.read<AuthProvider>().apiService)..load();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(value: provider, child: const _CategoriesContent());
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoriesProvider>();
    final income = provider.categories.where((category) => category.type == CategoryType.income).toList();
    final expense = provider.categories.where((category) => category.type == CategoryType.expense).toList();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(children: [
            Expanded(child: Text('Categories', style: Theme.of(context).textTheme.headlineSmall)),
            FilledButton.icon(onPressed: () => _showForm(context), icon: const Icon(Icons.add), label: const Text('Add category')),
          ]),
          const SizedBox(height: 16),
          if (provider.isLoading && provider.categories.isEmpty) const LoadingWidget(),
          if (provider.errorMessage != null) ...[
            ErrorMessage(message: provider.errorMessage!, onRetry: provider.load),
          ],
          if (!provider.isLoading && provider.errorMessage == null && provider.categories.isEmpty)
            const EmptyState(message: 'No categories yet. Add your first category.'),
          _CategorySection(title: 'Income', categories: income),
          _CategorySection(title: 'Expense', categories: expense),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, [TransactionCategory? category]) async {
    final result = await showDialog<_CategoryFormResult>(context: context, builder: (_) => _CategoryForm(category: category));
    if (result == null || !context.mounted) return;
    final provider = context.read<CategoriesProvider>();
    final success = category == null
        ? await provider.create(name: result.name, type: result.type)
        : await provider.update(category.id, name: result.name, type: result.type);
    if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(category == null ? 'Category created.' : 'Category updated.')));
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.title, required this.categories});

  final String title;
  final List<TransactionCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (categories.isEmpty) const Text('None'),
      for (final category in categories)
        Card(
          child: ListTile(
            leading: Icon(category.type == CategoryType.income ? Icons.trending_up : Icons.trending_down),
            title: Text(category.name),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => _edit(context, category)),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () async {
                  final success = await context.read<CategoriesProvider>().delete(category.id);
                  if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully.')));
                },
              ),
            ]),
          ),
        ),
    ]);
  }

  Future<void> _edit(BuildContext context, TransactionCategory category) async {
    final result = await showDialog<_CategoryFormResult>(context: context, builder: (_) => _CategoryForm(category: category));
    if (result != null && context.mounted) {
      final success = await context.read<CategoriesProvider>().update(category.id, name: result.name, type: result.type);
      if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category updated successfully.')));
    }
  }
}

class _CategoryFormResult {
  const _CategoryFormResult(this.name, this.type);

  final String name;
  final CategoryType type;
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.category});

  final TransactionCategory? category;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final name = TextEditingController(text: widget.category?.name);
  late CategoryType type = widget.category?.type ?? CategoryType.income;
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: (value) => value == null || value.trim().isEmpty ? 'Enter a category name' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: CategoryType.income, child: Text('income')),
                DropdownMenuItem(value: CategoryType.expense, child: Text('expense')),
              ],
              onChanged: (value) => setState(() => type = value ?? CategoryType.income),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, _CategoryFormResult(name.text.trim(), type));
  }
}