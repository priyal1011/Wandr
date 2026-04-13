import 'place_data.dart';

class DayData {
  final DateTime date;
  final List<PlaceData> places;
  DayData({required this.date, List<PlaceData>? places})
    : places = places ?? [];

  DayData copyWith({DateTime? date, List<PlaceData>? places}) =>
      DayData(date: date ?? this.date, places: places ?? this.places);

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'places': places.map((p) => p.toJson()).toList(),
  };

  factory DayData.fromJson(Map<String, dynamic> json) => DayData(
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    places:
        (json['places'] as List<dynamic>?)
            ?.map((p) => PlaceData.fromJson(p))
            .toList() ??
        [],
  );
}
