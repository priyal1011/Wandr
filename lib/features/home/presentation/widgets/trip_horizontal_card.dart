import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/in_memory_store.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/trips_cubit.dart';

class TripHorizontalCard extends StatelessWidget {
  final TripModel trip;

  const TripHorizontalCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = trip.endDate.isBefore(now);
    final statusColor = isPast ? Colors.grey : Colors.green;
    final statusText = isPast ? 'Past' : 'Upcoming';
    final dateStr = '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('d, yyyy').format(trip.endDate)}';

    return Dismissible(
      key: Key(trip.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        bool confirm = false;
        await AppConfirmDialog.show(
          context,
          title: 'Delete Trip',
          message: 'Are you sure you want to delete ${trip.name}? This removes all places, budget, and photos.',
          onConfirm: () => confirm = true,
        );
        return confirm;
      },
      onDismissed: (direction) {
        context.read<TripsCubit>().deleteTrip(trip.id);
        AppSnackbar.info(context, 'Trip deleted.');
      },
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      child: GestureDetector(
        onTap: () => context.push('/trip/${trip.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: trip.coverPhoto != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                        child: trip.coverPhoto!.startsWith('http')
                            ? Image.network(trip.coverPhoto!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)))
                            : Image.file(File(trip.coverPhoto!), fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey))),
                      )
                    : Center(
                        child: Text(
                          trip.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.destination,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
