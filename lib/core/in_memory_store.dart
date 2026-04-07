import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Models ───────────────────────────────────────────────

class UserModel {
  final String id;
  String name;
  String email;
  final String password;
  String? photoUrl;

  UserModel({required this.id, required this.name, required this.email, required this.password, this.photoUrl});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'password': password, 'photoUrl': photoUrl,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'], name: json['name'], email: json['email'], password: json['password'] ?? '', photoUrl: json['photoUrl'],
  );
}

class TripModel {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;
  final String currency;
  final String? coverPhoto;
  
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
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalBudget': totalBudget,
    'currency': currency,
    'coverPhoto': coverPhoto,
    'itinerary': itinerary?.map((d) => d.toJson()).toList(),
    'expenses': expenses?.map((e) => e.toJson()).toList(),
    'photos': photos?.map((p) => p.toJson()).toList(),
    'markerCoords': markers?.map((m) => {'lat': m.point.latitude, 'lng': m.point.longitude}).toList(),
  };

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final markerCoords = (json['markerCoords'] as List<dynamic>?)
        ?.map((m) => {'lat': (m['lat'] as num).toDouble(), 'lng': (m['lng'] as num).toDouble()})
        .toList();

    final trip = TripModel(
      id: json['id'],
      name: json['name'],
      destination: json['destination'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalBudget: (json['totalBudget'] as num).toDouble(),
      currency: json['currency'] ?? r'$',
      coverPhoto: json['coverPhoto'],
      itinerary: (json['itinerary'] as List<dynamic>?)?.map((d) => DayData.fromJson(d)).toList(),
      expenses: (json['expenses'] as List<dynamic>?)?.map((e) => ExpenseModel.fromJson(e)).toList(),
      photos: (json['photos'] as List<dynamic>?)?.map((p) => PhotoModel.fromJson(p)).toList(),
    );

    // Recreate Marker widgets from stored coordinates
    if (markerCoords != null && markerCoords.isNotEmpty) {
      trip.markers = markerCoords.map((c) => Marker(
        point: ll.LatLng(c['lat']!, c['lng']!),
        child: const Icon(Icons.location_on, color: Colors.indigo, size: 30),
      )).toList();
    }

    return trip;
  }
}

class DayData {
  final DateTime date;
  final List<PlaceData> places;
  DayData({required this.date, List<PlaceData>? places}) : places = places ?? [];

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'places': places.map((p) => p.toJson()).toList(),
  };

  factory DayData.fromJson(Map<String, dynamic> json) => DayData(
    date: DateTime.parse(json['date']),
    places: (json['places'] as List<dynamic>?)?.map((p) => PlaceData.fromJson(p)).toList(),
  );
}

class PlaceData {
  final String name;
  final String time;
  final String type;
  final String? notes;
  PlaceData({required this.name, required this.time, required this.type, this.notes});

  Map<String, dynamic> toJson() => {'name': name, 'time': time, 'type': type, 'notes': notes};

  factory PlaceData.fromJson(Map<String, dynamic> json) => PlaceData(
    name: json['name'], time: json['time'], type: json['type'], notes: json['notes'],
  );
}

class PlaceModel {
  final String id;
  final String tripId;
  final String name;
  final String category;
  final DateTime date;
  final String time;
  final String? notes;

  PlaceModel({required this.id, required this.tripId, required this.name, required this.category, required this.date, required this.time, this.notes});

  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'name': name, 'category': category, 'date': date.toIso8601String(), 'time': time, 'notes': notes,
  };

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
    id: json['id'], tripId: json['tripId'], name: json['name'], category: json['category'], date: DateTime.parse(json['date']), time: json['time'], notes: json['notes'],
  );
}

class ExpenseModel {
  final String id;
  final String tripId;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  ExpenseModel({required this.id, required this.tripId, required this.name, required this.amount, required this.category, required this.date, this.note});

  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'name': name, 'amount': amount, 'category': category, 'date': date.toIso8601String(), 'note': note,
  };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'], tripId: json['tripId'], name: json['name'], amount: (json['amount'] as num).toDouble(), category: json['category'], date: DateTime.parse(json['date']), note: json['note'],
  );
}

class PhotoModel {
  final String id;
  final String tripId;
  final String url;
  final String? caption;
  final String? dayId;

  PhotoModel({required this.id, required this.tripId, required this.url, this.caption, this.dayId});

  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'url': url, 'caption': caption, 'dayId': dayId,
  };

  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
    id: json['id'], tripId: json['tripId'], url: json['url'], caption: json['caption'], dayId: json['dayId'],
  );
}

class AppSettings {
  bool isDarkMode;
  AppSettings({required this.isDarkMode});
  
  factory AppSettings.defaults() => AppSettings(isDarkMode: false);

  Map<String, dynamic> toJson() => {'isDarkMode': isDarkMode};
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(isDarkMode: json['isDarkMode'] ?? false);
}

// ─── Dummy data (used only on first launch) ───────────────

final List<TripModel> dummyTrips = [
  TripModel(
    id: '1', name: 'Kyoto Spring', destination: 'Kyoto, Japan', totalBudget: 4000, currency: '\$', coverPhoto: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
    startDate: DateTime.now().add(const Duration(days: 10)), endDate: DateTime.now().add(const Duration(days: 17)),
    itinerary: [
      DayData(date: DateTime.now().add(const Duration(days: 10)), places: [
         PlaceData(name: 'Fushimi Inari', time: '09:00 AM', type: 'Activity', notes: 'Wear comfortable walking shoes.'),
         PlaceData(name: 'Nishiki Market', time: '12:30 PM', type: 'Food', notes: 'Try the tamagoyaki!'),
      ]),
    ],
  ),
  TripModel(id: '2', name: 'Alpine Escape', destination: 'Swiss Alps', startDate: DateTime.now().add(const Duration(days: 30)), endDate: DateTime.now().add(const Duration(days: 37)), totalBudget: 5500, currency: '\$', coverPhoto: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99'),
  TripModel(id: '103', name: 'Santorini Sunset', destination: 'Santorini, Greece', startDate: DateTime.now().add(const Duration(days: 45)), endDate: DateTime.now().add(const Duration(days: 52)), totalBudget: 3200, currency: '€', coverPhoto: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1'),
  TripModel(id: '104', name: 'NYC Winter', destination: 'New York City, USA', startDate: DateTime.now().add(const Duration(days: 60)), endDate: DateTime.now().add(const Duration(days: 65)), totalBudget: 2800, currency: '\$', coverPhoto: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9'),
  TripModel(id: '105', name: 'Bali Retreat', destination: 'Bali, Indonesia', startDate: DateTime.now().add(const Duration(days: 80)), endDate: DateTime.now().add(const Duration(days: 90)), totalBudget: 1500, currency: '\$', coverPhoto: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4'),
  TripModel(id: '106', name: 'Iceland Drive', destination: 'Reykjavik, Iceland', startDate: DateTime.now().add(const Duration(days: 100)), endDate: DateTime.now().add(const Duration(days: 110)), totalBudget: 4500, currency: '\$', coverPhoto: 'https://images.unsplash.com/photo-1476610182048-b716b8518aae'),
  TripModel(id: '107', name: 'Amazon Explore', destination: 'Manaus, Brazil', startDate: DateTime.now().add(const Duration(days: 150)), endDate: DateTime.now().add(const Duration(days: 160)), totalBudget: 2500, currency: '\$', coverPhoto: 'https://images.unsplash.com/photo-1518182170546-076616fd6cd5'),
  TripModel(id: '3', name: 'London Weekend', destination: 'London, UK', startDate: DateTime.now().subtract(const Duration(days: 30)), endDate: DateTime.now().subtract(const Duration(days: 27)), totalBudget: 1500, currency: '£', coverPhoto: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570'),
];

// ─── Persistent Store ─────────────────────────────────────

class InMemoryStore {
  static const _tripsKey = 'wandr_trips';
  static const _photosKey = 'wandr_photos';
  static const _settingsKey = 'wandr_settings';
  static const _hasDataKey = 'wandr_has_saved_data';

  UserModel? currentUser;
  List<TripModel> trips = [];
  List<PlaceModel> places = [];
  List<ExpenseModel> expenses = [];
  List<PhotoModel> photos = [];
  AppSettings settings = AppSettings.defaults();
  bool hasSeenOnboarding = false;

  void loginDemo() {
    currentUser = UserModel(id: '1', name: 'Alex', email: 'alex@wandr.com', password: 'password123');
  }

  /// Load all data from SharedPreferences. If no saved data exists, seeds with dummy trips.
  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSavedData = prefs.getBool(_hasDataKey) ?? false;

      if (!hasSavedData) {
        // First launch — seed with dummy data
        trips = [...dummyTrips];
        debugPrint('[Wandr] First launch — seeded ${trips.length} dummy trips.');
        await saveToDisk();
        return;
      }

      // Load trips
      final tripsJson = prefs.getString(_tripsKey);
      if (tripsJson != null) {
        final List<dynamic> decoded = jsonDecode(tripsJson);
        trips = decoded.map((t) => TripModel.fromJson(t)).toList();
      }

      // Load global photos
      final photosJson = prefs.getString(_photosKey);
      if (photosJson != null) {
        final List<dynamic> decoded = jsonDecode(photosJson);
        photos = decoded.map((p) => PhotoModel.fromJson(p)).toList();
      }

      // Load settings
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        settings = AppSettings.fromJson(jsonDecode(settingsJson));
      }

      debugPrint('[Wandr] Loaded ${trips.length} trips, ${photos.length} photos from disk.');
    } catch (e) {
      debugPrint('[Wandr] Load error: $e — falling back to dummy data.');
      trips = [...dummyTrips];
    }
  }

  /// Save all current data to SharedPreferences.
  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tripsKey, jsonEncode(trips.map((t) => t.toJson()).toList()));
      await prefs.setString(_photosKey, jsonEncode(photos.map((p) => p.toJson()).toList()));
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
      await prefs.setBool(_hasDataKey, true);
      debugPrint('[Wandr] Saved ${trips.length} trips, ${photos.length} photos to disk.');
    } catch (e) {
      debugPrint('[Wandr] Save error: $e');
    }
  }
}
