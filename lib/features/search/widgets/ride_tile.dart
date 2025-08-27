import 'package:flutter/material.dart';
import '../../../core/api.dart'; // for Ride model

class RideTile extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;
  const RideTile({super.key, required this.ride, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.directions_car)),
      title: Text('${ride.from} → ${ride.to}'),
      subtitle: Text('${ride.dateLabel} • ${ride.timeLabel} • ₹${ride.price}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${ride.spots} seats',
              style: theme.textTheme.labelMedium),
          if (ride.cashbackPct != null)
            Text('${ride.cashbackPct}% CB',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )),
        ],
      ),
    );
  }
}
