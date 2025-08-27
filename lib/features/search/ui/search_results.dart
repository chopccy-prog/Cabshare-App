// lib/features/search/ui/search_results.dart
import 'package:flutter/material.dart';
import '../../../core/models/ride.dart';

class SearchResults extends StatelessWidget {
  final List<Ride> rides;
  final void Function(Ride ride)? onTap;

  const SearchResults({super.key, required this.rides, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return const Center(child: Text('No rides found'));
    }
    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (_, i) {
        final r = rides[i];
        final local = r.when.toLocal();
        final date = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
        final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

        return ListTile(
          title: Text('${r.from} → ${r.to}'),
          subtitle: Text('$date • $time • ${r.seats} seats'),
          trailing: Text(r.price > 0 ? '₹${r.price.toStringAsFixed(0)}' : '—'),
          onTap: onTap == null ? null : () => onTap!(r),
        );
      },
    );
  }
}
