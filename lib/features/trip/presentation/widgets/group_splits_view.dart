import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class GroupSplitsView extends StatelessWidget {
  final Map<String, double> balances;
  final List<Map<String, dynamic>> settlements;
  final String currency;

  const GroupSplitsView({
    super.key,
    required this.balances,
    required this.settlements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
      children: [
        Text('BALANCES', 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)),
        const Gap(12),
        ...balances.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${e.value >= 0 ? '+' : ''}$currency${e.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: e.value >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        )),
        const Gap(24),
        Text('SUGGESTED SETTLEMENTS', 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)),
        const Gap(12),
        if (settlements.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('All settled up! 🎉', style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))),
          ))
        else
          ...settlements.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent.withValues(alpha: 0.05), Colors.lightBlueAccent.withValues(alpha: 0.02)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['from'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Text('should pay', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.lightBlueAccent, size: 20),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(s['to'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$currency${s['amount'].toStringAsFixed(0)}', 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.lightBlueAccent)),
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    ).animate().fadeIn();
  }
}
