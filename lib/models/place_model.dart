class PlaceModel {
  final String id;
  final String tripId;
  final String name;
  final String category;
  final DateTime date;
  final String time;
  final String? notes;

  PlaceModel({
    required this.id,
    required this.tripId,
    required this.name,
    required this.category,
    required this.date,
    required this.time,
    this.notes,
  });

  PlaceModel copyWith({
    String? name,
    String? category,
    DateTime? date,
    String? time,
    String? notes,
  }) => PlaceModel(
    id: id,
    tripId: tripId,
    name: name ?? this.name,
    category: category ?? this.category,
    date: date ?? this.date,
    time: time ?? this.time,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'name': name,
    'category': category,
    'date': date.toIso8601String(),
    'time': time,
    'notes': notes,
  };

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
    id: json['id']?.toString() ?? '',
    tripId: json['tripId']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Unnamed Place',
    category: json['category']?.toString() ?? 'Activity',
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    time: json['time']?.toString() ?? 'Morning',
    notes: json['notes']?.toString(),
  );
}
