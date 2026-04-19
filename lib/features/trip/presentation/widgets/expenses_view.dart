// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:wandr/core/widgets/interactive_dialog.dart';
import 'package:wandr/models/trip_model.dart';
import 'package:wandr/models/expense_model.dart';
import 'expense_card.dart';
import 'group_splits_view.dart';

class ExpensesView extends StatefulWidget {
  final TripModel trip;
  final Function(List<ExpenseModel>) onUpdate;

  const ExpensesView({
    super.key,
    required this.trip,
    required this.onUpdate,
  });

  @override
  State<ExpensesView> createState() => ExpensesViewState();
}

class ExpensesViewState extends State<ExpensesView> {
  late List<ExpenseModel> _expenses;

  @override
  void initState() {
    super.initState();
    _expenses = widget.trip.expenses ?? [];
  }

  double get _totalSpent => _expenses.fold(0, (sum, item) => sum + item.amount);

  void showAddExpense() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Food';
    
    final List<String> participants = ['Me', ...(widget.trip.companions ?? [])];
    String paidBy = 'Me';
    List<String> splitWith = List.from(participants);
    bool isSplit = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => InteractiveDialog(
          title: 'Track Expense',
          icon: Icons.payments_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                stylusHandwritingEnabled: false,
controller: nameCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'What did you buy?',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      stylusHandwritingEnabled: false,
controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Amount (${widget.trip.currency})',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: ['Food', 'Transport', 'Stay', 'Shopping', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setDialogState(() => category = v!),
                    ),
                  ),
                ],
              ),
              if (participants.length > 1) ...[
                const Gap(8),
                SwitchListTile(
                  title: const Text('Split with friends?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Track who owes whom', style: TextStyle(fontSize: 11)),
                  value: isSplit,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setDialogState(() => isSplit = v),
                ),
                if (isSplit) ...[
                  const Gap(8),
                  DropdownButtonFormField<String>(
                    value: paidBy,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Who Paid?',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: participants.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setDialogState(() => paidBy = v!),
                  ),
                  const Gap(12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Split with...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const Gap(8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: participants.map((p) {
                        return CheckboxListTile(
                          title: Text(p, style: const TextStyle(fontSize: 13)),
                          value: splitWith.contains(p),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (v) {
                            setDialogState(() {
                              if (v == true) {
                                splitWith.add(p);
                              } else if (splitWith.length > 1) {
                                splitWith.remove(p);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                if (nameCtrl.text.isEmpty) return;
                setState(() {
                  _expenses.add(ExpenseModel(
                    id: DateTime.now().toString(),
                    tripId: widget.trip.id,
                    name: nameCtrl.text,
                    amount: amount,
                    category: category,
                    date: DateTime.now(),
                    paidBy: isSplit ? paidBy : 'Me',
                    splitWith: isSplit ? splitWith : ['Me'],
                  ));
                  widget.onUpdate(_expenses);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
              child: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  void _editExpense(int index) async {
    final expense = _expenses[index];
    final nameCtrl = TextEditingController(text: expense.name);
    final amountCtrl = TextEditingController(text: expense.amount.toString());
    String category = expense.category;
    
    final List<String> participants = ['Me', ...(widget.trip.companions ?? [])];
    String paidBy = expense.paidBy ?? 'Me';
    List<String> splitWith = List.from(expense.splitWith ?? ['Me']);
    bool isSplit = expense.splitWith != null && expense.splitWith!.length > 1;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => InteractiveDialog(
          title: 'Edit Expense',
          icon: Icons.edit_note_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                stylusHandwritingEnabled: false,
controller: nameCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'What did you buy?',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      stylusHandwritingEnabled: false,
controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Amount (${widget.trip.currency})',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: ['Food', 'Transport', 'Stay', 'Shopping', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setDialogState(() => category = v!),
                    ),
                  ),
                ],
              ),
              if (participants.length > 1) ...[
                const Gap(8),
                SwitchListTile(
                  title: const Text('Split with friends?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: isSplit,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setDialogState(() => isSplit = v),
                ),
                if (isSplit) ...[
                  const Gap(8),
                  DropdownButtonFormField<String>(
                    value: paidBy,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Who Paid?',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: participants.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setDialogState(() => paidBy = v!),
                  ),
                  const Gap(12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: participants.map((p) {
                        return CheckboxListTile(
                          title: Text(p, style: const TextStyle(fontSize: 13)),
                          value: splitWith.contains(p),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (v) {
                            setDialogState(() {
                              if (v == true) {
                                splitWith.add(p);
                              } else if (splitWith.length > 1) {
                                splitWith.remove(p);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(amountCtrl.text) ?? 0.0;
      setState(() {
        _expenses[index] = expense.copyWith(
          name: nameCtrl.text,
          amount: amount,
          category: category,
          paidBy: isSplit ? paidBy : 'Me',
          splitWith: isSplit ? splitWith : ['Me'],
        );
        widget.onUpdate(_expenses);
      });
    }
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
      widget.onUpdate(_expenses);
    });
  }

  String _viewMode = 'Ledger'; // 'Ledger' or 'Splits'

  Map<String, double> _calculateBalances() {
    final Map<String, double> balances = {};
    // Init all companions + Me
    final participants = ['Me', ...(widget.trip.companions ?? [])];
    for (var p in participants) {
      balances[p] = 0.0;
    }

    for (var expense in _expenses) {
      final payer = expense.paidBy ?? 'Me';
      final inSplit = expense.splitWith ?? ['Me'];
      if (inSplit.isEmpty || expense.amount == 0) continue;
      
      final share = expense.amount / inSplit.length;
      
      // Payer gets back the full amount
      balances[payer] = (balances[payer] ?? 0.0) + expense.amount;
      
      // Everyone in the split (including payer) owes their share
      for (var person in inSplit) {
        balances[person] = (balances[person] ?? 0.0) - share;
      }
    }
    return balances;
  }

  List<Map<String, dynamic>> _calculateSettlements(Map<String, double> balances) {
    final List<Map<String, dynamic>> settlements = [];
    final creditors = balances.entries.where((e) => e.value > 0.01).map((e) => {'name': e.key, 'val': e.value}).toList();
    final debtors = balances.entries.where((e) => e.value < -0.01).map((e) => {'name': e.key, 'val': e.value.abs()}).toList();

    int c = 0, d = 0;
    while (c < creditors.length && d < debtors.length) {
      final creditor = creditors[c];
      final debtor = debtors[d];
      
      final double amount = (creditor['val'] as double) < (debtor['val'] as double) 
          ? (creditor['val'] as double) 
          : (debtor['val'] as double);
      
      settlements.add({
        'from': debtor['name'],
        'to': creditor['name'],
        'amount': amount,
      });

      creditors[c]['val'] = (creditors[c]['val'] as double) - amount;
      debtors[d]['val'] = (debtors[d]['val'] as double) - amount;

      if ((creditors[c]['val'] as double) < 0.01) c++;
      if ((debtors[d]['val'] as double) < 0.01) d++;
    }
    return settlements;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBudgetCard(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              if (widget.trip.companions != null && widget.trip.companions!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildViewTab('Ledger'),
                      _buildViewTab('Splits'),
                    ],
                  ),
                ),
                const Gap(16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_viewMode == 'Ledger' ? 'Expenses' : 'Settlements', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_viewMode == 'Ledger')
                    TextButton.icon(
                      onPressed: showAddExpense, 
                      icon: const Icon(Icons.add, size: 18), 
                      label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: Colors.lightBlueAccent),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewMode == 'Ledger' 
            ? (_expenses.isEmpty ? _buildEmptyState() : _buildExpensesList())
            : GroupSplitsView(
                balances: _calculateBalances(),
                settlements: _calculateSettlements(_calculateBalances()),
                currency: widget.trip.currency,
              ),
        ),
      ],
    );
  }

  Widget _buildViewTab(String mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          child: Text(
            mode == 'Ledger' ? 'My Ledger' : 'Group Splits',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.lightBlueAccent : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return ExpenseCard(
          expense: expense,
          index: index,
          currency: widget.trip.currency,
          onEdit: () => _editExpense(index),
          onDelete: () => _deleteExpense(index),
        );
      },
    );
  }


  Widget _buildBudgetCard() {
    final remaining = widget.trip.totalBudget - _totalSpent;
    final percent = widget.trip.totalBudget > 0 ? (_totalSpent / widget.trip.totalBudget).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip Budget', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Track your spending', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${widget.trip.currency}${_totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('of ${widget.trip.currency}${widget.trip.totalBudget}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Gap(20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(percent * 100).toStringAsFixed(1)}% spent', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              remaining >= 0
                ? Text(
                    '${widget.trip.currency}${remaining.toStringAsFixed(0)} remaining',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  )
                : Text(
                    '${widget.trip.currency}${remaining.abs().toStringAsFixed(0)} overspent',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasSpace = constraints.maxHeight > 100;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: hasSpace ? 64 : 32, // Adaptive size
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              const Gap(16),
              Text(
                'No expenses recorded yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  fontSize: hasSpace ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
