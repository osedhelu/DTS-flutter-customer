import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/stores_providers.dart';

class StoreListScreen extends ConsumerWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Comercios')),
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(child: Text('No hay comercios disponibles'));
          }
          return ListView.separated(
            itemCount: stores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final store = stores[index];
              return ListTile(
                key: Key('store_tile_${store.id}'),
                leading: store.logoUrl != null && store.logoUrl!.isNotEmpty
                    ? Image.network(store.logoUrl!, width: 48, height: 48)
                    : const Icon(Icons.store),
                title: Text(store.name),
                subtitle: store.address != null ? Text(store.address!) : null,
                trailing: store.isOpen
                    ? const Icon(Icons.chevron_right)
                    : const Text('Cerrado'),
                onTap: store.isOpen
                    ? () => context.push('/stores/${store.id}/catalog')
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
