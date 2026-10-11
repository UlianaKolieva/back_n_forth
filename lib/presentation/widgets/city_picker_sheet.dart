import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/city.dart';
import '../providers/city_provider.dart';

Future<void> showCityPicker(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.85, child: CityPickerSheet()),
    );

class CityPickerSheet extends ConsumerStatefulWidget {
  const CityPickerSheet({super.key});

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  String _query = '';
  String? _loadingSlug;

  Future<void> _select(City city) async {
    setState(() => _loadingSlug = city.slug);
    try {
      await ref.read(activeCityProvider.notifier).select(city);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${city.name}: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingSlug = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allCitiesProvider).valueOrNull ?? [];
    final downloaded = {for (final c in ref.watch(downloadedCitiesProvider).valueOrNull ?? <City>[]) c.slug};
    final active = ref.watch(activeCityProvider);
    final q = _query.toLowerCase();
    final cities = all.where((c) => c.name.toLowerCase().contains(q)).toList()
      ..sort((a, b) => (downloaded.contains(b.slug) ? 1 : 0) - (downloaded.contains(a.slug) ? 1 : 0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: active == null,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Поиск города',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: cities.length,
            itemBuilder: (_, i) {
              final city = cities[i];
              final isDownloaded = downloaded.contains(city.slug);
              return ListTile(
                title: Text(city.name),
                selected: active?.slug == city.slug,
                leading: Icon(isDownloaded ? Icons.offline_pin : Icons.cloud_download_outlined),
                trailing: _loadingSlug == city.slug
                    ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : isDownloaded
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Удалить остановки',
                            onPressed: () => ref.read(activeCityProvider.notifier).delete(city),
                          )
                        : null,
                onTap: _loadingSlug == null ? () => _select(city) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
