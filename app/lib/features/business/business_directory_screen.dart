import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/business_card.dart';
import 'business_providers.dart';

class BusinessDirectoryScreen extends ConsumerStatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  ConsumerState<BusinessDirectoryScreen> createState() =>
      _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState
    extends ConsumerState<BusinessDirectoryScreen> {
  String _category = '';

  @override
  Widget build(BuildContext context) {
    final businesses = ref.watch(directoryProvider(_category)).value ?? const [];
    final categories = ['All', ...AppConfig.industries];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Add a business',
            onPressed: () => context.push('/business/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: (c == 'All' && _category.isEmpty) || c == _category,
                      onSelected: (_) =>
                          setState(() => _category = c == 'All' ? '' : c),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: businesses.isEmpty
                ? const Center(child: Text('No businesses listed here yet.'))
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final b in businesses) BusinessCard(business: b),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
