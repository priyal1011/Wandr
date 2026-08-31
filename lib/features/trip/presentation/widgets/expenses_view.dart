// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:wandr/core/in_memory_store.dart';
import 'package:wandr/core/widgets/interactive_dialog.dart';

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
                controller: nameCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'What did you buy?',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Amount (${widget.trip.currency})',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                      fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
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
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
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
                controller: nameCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'What did you buy?',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Amount (${widget.trip.currency})',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                      fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: participants.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setDialogState(() => paidBy = v!),
                  ),
                  const Gap(12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold)),
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
            : _buildSplitsView(),
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
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
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
        return _buildExpenseCard(expense, index);
      },
    );
  }

  Widget _buildSplitsView() {
    final balances = _calculateBalances();
    final settlements = _calculateSettlements(balances);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
      children: [
        Text('BALANCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)),
        const Gap(12),
        ...balances.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${e.value >= 0 ? '+' : ''}${widget.trip.currency}${e.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: e.value >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        )),
        const Gap(24),
        Text('SUGGESTED SETTLEMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)),
        const Gap(12),
        if (settlements.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('All settled up! 🎉', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
          ))
        else
          ...settlements.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent.withOpacity(0.05), Colors.lightBlueAccent.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.1)),
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
                      Text('${widget.trip.currency}${s['amount'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.lightBlueAccent)),
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    ).animate().fadeIn();
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
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
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
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
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
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: constraints.maxHeight > 0 ? constraints.maxHeight : 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No expenses recorded yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(_getCategoryIcon(expense.category), color: Colors.lightBlueAccent, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Text(DateFormat('MMM dd').format(expense.date), style: TextStyle(color: Colors.grey, fontSize: 12)),
                    if (expense.splitWith != null && expense.splitWith!.length > 1) ...[
                      Text(' • ', style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12)),
                      Icon(Icons.group_outlined, size: 12, color: Colors.lightBlueAccent.withOpacity(0.7)),
                      const Gap(4),
                      Text('Split with ${expense.splitWith!.length}', style: TextStyle(color: Colors.lightBlueAccent.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                if (expense.paidBy != null && expense.paidBy != 'Me') ...[
                  const Gap(2),
                  Text('Paid by ${expense.paidBy}', style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 10, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${widget.trip.currency}${expense.amount.toStringAsFixed(0)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey.withOpacity(0.5)),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'edit') _editExpense(index);
                  if (val == 'delete') _deleteExpense(index);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), Gap(8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), Gap(8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
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
