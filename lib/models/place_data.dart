class PlaceData {
  final String name;
  final String time;
  final String type;
  final String? notes;
  PlaceData({
    required this.name,
    required this.time,
    required this.type,
    this.notes,
  });

  PlaceData copyWith({
    String? name,
    String? time,
    String? type,
    String? notes,
  }) => PlaceData(
    name: name ?? this.name,
    time: time ?? this.time,
    type: type ?? this.type,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'time': time,
    'type': type,
    'notes': notes,
  };

  factory PlaceData.fromJson(Map<String, dynamic> json) => PlaceData(
    name: json['name']?.toString() ?? 'Interesting Spot',
    time: json['time']?.toString() ?? 'Flexible Time',
    type: json['type']?.toString() ?? 'Activity',
    notes: json['notes']?.toString(),
  );
}
