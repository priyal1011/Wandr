import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final int index;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.index,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Strong centering for the whole row
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(_getCategoryIcon(expense.category), color: Colors.lightBlueAccent, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          expense.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2, // Allow wrapping if name is long
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        '$currency${expense.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(1), // Balanced separation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM dd').format(expense.date),
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (expense.splitWith != null && expense.splitWith!.length > 1) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          Icon(
                            Icons.group_outlined,
                            size: 15,
                            color: Colors.lightBlueAccent.withValues(alpha: 0.7),
                          ),
                          const Gap(5),
                          Text(
                            'Split with ${expense.splitWith!.length}',
                            style: TextStyle(
                              color: Colors.lightBlueAccent.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildMoreButton(),
                  ],
                ),
                if (expense.paidBy != null && expense.paidBy != 'Me') ...[
                  const Gap(2),
                  Text(
                    'Paid by ${expense.paidBy}',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
  }

  Widget _buildMoreButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 18,
        color: Colors.grey.withValues(alpha: 0.5),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_outlined, size: 18), Gap(8), Text('Edit')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              Gap(8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant_outlined;
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Stay': return Icons.hotel_outlined;
      case 'Shopping': return Icons.shopping_bag_outlined;
      default: return Icons.more_horiz_outlined;
    }
  }
}
