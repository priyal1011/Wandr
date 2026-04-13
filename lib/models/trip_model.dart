import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'day_data.dart';
import 'expense_model.dart';
import 'photo_model.dart';

class TripModel {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;
  final String currency;
  final String? coverPhoto;
  List<String>? companions;
  List<DayData>? itinerary;
  List<ExpenseModel>? expenses;
  List<PhotoModel>? photos;
  List<Marker>? markers;

  TripModel({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
    required this.currency,
    this.coverPhoto,
    this.itinerary,
    this.expenses,
    this.photos,
    this.markers,
    this.companions,
  });

  TripModel copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? totalBudget,
    String? currency,
    String? coverPhoto,
    List<String>? companions,
    List<DayData>? itinerary,
    List<PhotoModel>? photos,
  }) => TripModel(
    id: id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    totalBudget: totalBudget ?? this.totalBudget,
    currency: currency ?? this.currency,
    coverPhoto: coverPhoto ?? this.coverPhoto,
    companions: companions ?? this.companions,
    itinerary: itinerary ?? this.itinerary,
    photos: photos ?? this.photos,
    markers: markers,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalBudget': totalBudget,
    'currency': currency,
    'coverPhoto': coverPhoto,
    'companions': companions,
    'itinerary': itinerary?.map((d) => d.toJson()).toList(),
    'expenses': expenses?.map((e) => e.toJson()).toList(),
    'photos': photos?.map((p) => p.toJson()).toList(),
    'markerCoords': markers
        ?.map((m) => {'lat': m.point.latitude, 'lng': m.point.longitude})
        .toList(),
  };

  factory TripModel.fromJson(Map<String, dynamic> json) {
    String id = json['id']?.toString() ?? '';
    if (id.isEmpty) id = 'temp_${DateTime.now().microsecondsSinceEpoch}';

    final markerCoordsRaw = json['markerCoords'] as List<dynamic>?;
    final markerCoords = markerCoordsRaw?.map((m) {
      if (m is! Map) return {'lat': 0.0, 'lng': 0.0};
      return {
        'lat': (m['lat'] as num?)?.toDouble() ?? 0.0,
        'lng': (m['lng'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    final trip = TripModel(
      id: id,
      name: json['name']?.toString() ?? 'Untitled Journey',
      destination: json['destination']?.toString() ?? 'Unknown',
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      totalBudget: double.tryParse(json['totalBudget']?.toString() ?? '') ?? 0.0,
      currency: json['currency']?.toString() ?? r'$',
      coverPhoto: json['coverPhoto']?.toString(),
      itinerary: (json['itinerary'] as List<dynamic>?)?.map((d) => DayData.fromJson(d as Map<String, dynamic>)).toList(),
      expenses: (json['expenses'] as List<dynamic>?)?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList(),
      photos: (json['photos'] as List<dynamic>?)?.map((p) => PhotoModel.fromJson(p as Map<String, dynamic>)).toList(),
      companions: (json['companions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );

    if (markerCoords != null) {
      trip.markers = markerCoords.map((c) {
        return Marker(
          point: ll.LatLng(
            (c['lat'] as num?)?.toDouble() ?? 0.0,
            (c['lng'] as num?)?.toDouble() ?? 0.0,
          ),
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFD97706),
            size: 30,
          ),
        );
      }).toList();
    }
    return trip;
  }
}
