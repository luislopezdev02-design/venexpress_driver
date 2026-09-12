import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/common_widgets.dart';
import 'package_detail_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _searchController = TextEditingController();

  final Map<String, String> _filters = const {
    'all': 'Todos',
    'pending': 'Pendientes',
    'in_progress': 'En proceso',
    'delivered': 'Entregados',
    'incidents': 'Con incidencias',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadPackages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por guía, destinatario o ciudad',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder),
                ),
              ),
              onSubmitted: (value) {
                context.read<DriverProvider>().loadPackages(search: value.trim());
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.entries.map((entry) {
                final isSelected = provider.packagesFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: kPrimaryDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : kPrimaryDark,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: kBorder),
                    onSelected: (_) {
                      context.read<DriverProvider>().loadPackages(
                            status: entry.key,
                            search: _searchController.text.trim(),
                          );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<DriverProvider>().loadPackages(
                    search: _searchController.text.trim(),
                  ),
              child: provider.isLoadingPackages
                  ? const Center(child: CircularProgressIndicator())
                  : provider.packagesError != null
                      ? Center(child: Text(provider.packagesError!, style: const TextStyle(color: kMuted)))
                      : provider.packages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No tienes pedidos en este filtro.',
                                  style: TextStyle(color: kMuted),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: provider.packages.length,
                              itemBuilder: (context, index) {
                                final package = provider.packages[index];
                                return PackageListTile(
                                  package: package,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PackageDetailScreen(packageId: package.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
