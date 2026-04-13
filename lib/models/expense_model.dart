class ExpenseModel {
  final String id;
  final String tripId;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String? paidBy;
  final List<String>? splitWith;

  ExpenseModel({
    required this.id,
    required this.tripId,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.paidBy,
    this.splitWith,
  });

  ExpenseModel copyWith({
    String? name,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? paidBy,
    List<String>? splitWith,
  }) => ExpenseModel(
    id: id,
    tripId: tripId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    note: note ?? this.note,
    paidBy: paidBy ?? this.paidBy,
    splitWith: splitWith ?? this.splitWith,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'name': name,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
    'paidBy': paidBy,
    'splitWith': splitWith,
  };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id']?.toString() ?? DateTime.now().toString(),
    tripId: json['tripId']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Expense',
    amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
    category: json['category']?.toString() ?? 'General',
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    note: json['note']?.toString(),
    paidBy: json['paidBy']?.toString(),
    splitWith: (json['splitWith'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
  );
}
