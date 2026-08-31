import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

// ─── Models ───────────────────────────────────────────────

class UserModel {
  final String id;
  String name;
  String email;
  final String password;
  String? photoUrl;
  String? fluttermojiCode;

  UserModel({required this.id, required this.name, required this.email, required this.password, this.photoUrl, this.fluttermojiCode});

  UserModel copyWith({String? name, String? email, String? photoUrl, String? fluttermojiCode}) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password,
    photoUrl: photoUrl ?? this.photoUrl,
    fluttermojiCode: fluttermojiCode ?? this.fluttermojiCode,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'password': password, 'photoUrl': photoUrl, 'fluttermojiCode': fluttermojiCode,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Explorer',
    email: json['email'] ?? '',
    password: json['password'] ?? '',
    photoUrl: json['photoUrl'],
    fluttermojiCode: json['fluttermojiCode'],
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

  TripModel copyWith({String? name, String? destination, DateTime? startDate, DateTime? endDate, double? totalBudget, String? currency, String? coverPhoto, List<DayData>? itinerary, List<PhotoModel>? photos}) => TripModel(
    id: id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    totalBudget: totalBudget ?? this.totalBudget,
    currency: currency ?? this.currency,
    coverPhoto: coverPhoto ?? this.coverPhoto,
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
    'itinerary': itinerary?.map((d) => d.toJson()).toList(),
    'expenses': expenses?.map((e) => e.toJson()).toList(),
    'photos': photos?.map((p) => p.toJson()).toList(),
    'markerCoords': markers?.map((m) => {'lat': m.point.latitude, 'lng': m.point.longitude}).toList(),
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
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      totalBudget: double.tryParse(json['totalBudget']?.toString() ?? '') ?? 0.0,
      currency: json['currency']?.toString() ?? r'$',
      coverPhoto: json['coverPhoto']?.toString(),
      itinerary: (json['itinerary'] as List<dynamic>?)?.map((d) => DayData.fromJson(d as Map<String, dynamic>)).toList(),
      expenses: (json['expenses'] as List<dynamic>?)?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList(),
      photos: (json['photos'] as List<dynamic>?)?.map((p) => PhotoModel.fromJson(p as Map<String, dynamic>)).toList(),
    );

    if (markerCoords != null) {
      trip.markers = markerCoords.map((c) {
        return Marker(
          point: ll.LatLng((c['lat'] as num?)?.toDouble() ?? 0.0, (c['lng'] as num?)?.toDouble() ?? 0.0),
          child: const Icon(Icons.location_on, color: Color(0xFFD97706), size: 30),
        );
      }).toList();
    }
    return trip;
  }
}

class DayData {
  final DateTime date;
  final List<PlaceData> places;
  DayData({required this.date, List<PlaceData>? places}) : places = places ?? [];

  DayData copyWith({DateTime? date, List<PlaceData>? places}) => DayData(
    date: date ?? this.date,
    places: places ?? this.places,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'places': places.map((p) => p.toJson()).toList(),
  };

  factory DayData.fromJson(Map<String, dynamic> json) => DayData(
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    places: (json['places'] as List<dynamic>?)?.map((p) => PlaceData.fromJson(p)).toList() ?? [],
  );
}

class PlaceData {
  final String name;
  final String time;
  final String type;
  final String? notes;
  PlaceData({required this.name, required this.time, required this.type, this.notes});

  PlaceData copyWith({String? name, String? time, String? type, String? notes}) => PlaceData(
    name: name ?? this.name,
    time: time ?? this.time,
    type: type ?? this.type,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {'name': name, 'time': time, 'type': type, 'notes': notes};

  factory PlaceData.fromJson(Map<String, dynamic> json) => PlaceData(
    name: json['name']?.toString() ?? 'Interesting Spot',
    time: json['time']?.toString() ?? 'Flexible Time',
    type: json['type']?.toString() ?? 'Activity',
    notes: json['notes']?.toString(),
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

  PlaceModel copyWith({String? name, String? category, DateTime? date, String? time, String? notes}) => PlaceModel(
    id: id,
    tripId: tripId,
    name: name ?? this.name,
    category: category ?? this.category,
    date: date ?? this.date,
    time: time ?? this.time,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'name': name, 'category': category, 'date': date.toIso8601String(), 'time': time, 'notes': notes,
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

class ExpenseModel {
  final String id;
  final String tripId;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  ExpenseModel({required this.id, required this.tripId, required this.name, required this.amount, required this.category, required this.date, this.note});

  ExpenseModel copyWith({String? name, double? amount, String? category, DateTime? date, String? note}) => ExpenseModel(
    id: id,
    tripId: tripId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'name': name, 'amount': amount, 'category': category, 'date': date.toIso8601String(), 'note': note,
  };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id']?.toString() ?? DateTime.now().toString(),
    tripId: json['tripId']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Expense',
    amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
    category: json['category']?.toString() ?? 'General',
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    note: json['note']?.toString(),
  );
}

class PhotoModel {
  final String id;
  final String? tripId;
  final String url;
  final String? caption;
  final String? dayId;

  PhotoModel({required this.id, this.tripId, required this.url, this.caption, this.dayId});

  PhotoModel copyWith({String? url, String? caption, String? dayId}) => PhotoModel(
    id: id,
    tripId: tripId,
    url: url ?? this.url,
    caption: caption ?? this.caption,
    dayId: dayId ?? this.dayId,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'url': url, 'caption': caption, 'dayId': dayId,
  };

  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
    id: json['id'] ?? DateTime.now().toString(),
    tripId: json['tripId'],
    url: json['url'] ?? '',
    caption: json['caption'],
    dayId: json['dayId'],
  );
}

class AppSettings {
  bool isDarkMode;
  String currency;
  AppSettings({required this.isDarkMode, required this.currency});
  
  factory AppSettings.defaults() => AppSettings(isDarkMode: false, currency: r'$');

  Map<String, dynamic> toJson() => {'isDarkMode': isDarkMode, 'currency': currency};
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    isDarkMode: json['isDarkMode'] ?? false,
    currency: json['currency'] ?? r'$',
  );
}

// ─── Dummy data (used only on first launch) ───────────────

final List<TripModel> dummyTrips = [
  TripModel(
    id: '1', name: 'Kyoto Spring', destination: 'Kyoto, Japan', totalBudget: 4000, currency: r'$', coverPhoto: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
    startDate: DateTime.now().add(const Duration(days: 10)), endDate: DateTime.now().add(const Duration(days: 17)),
    itinerary: [
      DayData(date: DateTime.now().add(const Duration(days: 10)), places: [
         PlaceData(name: 'Fushimi Inari', time: '09:00 AM', type: 'Activity', notes: 'Wear comfortable walking shoes.'),
         PlaceData(name: 'Nishiki Market', time: '12:30 PM', type: 'Food', notes: 'Try the tamagoyaki!'),
      ]),
    ],
  ),
  TripModel(id: '2', name: 'Alpine Escape', destination: 'Swiss Alps', startDate: DateTime.now().add(const Duration(days: 30)), endDate: DateTime.now().add(const Duration(days: 37)), totalBudget: 5500, currency: r'$', coverPhoto: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99'),
  TripModel(id: '103', name: 'Santorini Sunset', destination: 'Santorini, Greece', startDate: DateTime.now().add(const Duration(days: 45)), endDate: DateTime.now().add(const Duration(days: 52)), totalBudget: 3200, currency: r'€', coverPhoto: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1'),
  TripModel(id: '104', name: 'NYC Winter', destination: 'New York City, USA', startDate: DateTime.now().add(const Duration(days: 60)), endDate: DateTime.now().add(const Duration(days: 65)), totalBudget: 2800, currency: r'$', coverPhoto: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9'),
  TripModel(id: '105', name: 'Bali Retreat', destination: 'Bali, Indonesia', startDate: DateTime.now().add(const Duration(days: 80)), endDate: DateTime.now().add(const Duration(days: 90)), totalBudget: 1500, currency: r'$', coverPhoto: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4'),
  TripModel(id: '106', name: 'Iceland Drive', destination: 'Reykjavik, Iceland', startDate: DateTime.now().add(const Duration(days: 100)), endDate: DateTime.now().add(const Duration(days: 110)), totalBudget: 4500, currency: r'$', coverPhoto: 'https://images.unsplash.com/photo-1476610182048-b716b8518aae'),
  TripModel(id: '107', name: 'Amazon Explore', destination: 'Manaus, Brazil', startDate: DateTime.now().add(const Duration(days: 150)), endDate: DateTime.now().add(const Duration(days: 160)), totalBudget: 2500, currency: r'$', coverPhoto: 'https://images.unsplash.com/photo-1518182170546-076616fd6cd5'),
];

// ─── Persistent Store ─────────────────────────────────────

class InMemoryStore extends ChangeNotifier {
  static const _tripsKey = 'wandr_trips';
  static const _photosKey = 'wandr_photos';
  static const _settingsKey = 'wandr_settings';
  static const _userKey = 'wandr_user';
  static const _hasDataKey = 'wandr_has_saved_data';

  UserModel? currentUser;
  String currentCurrency = r'$';
  bool hasSeenOnboarding = false;
  List<TripModel> trips = [];
  List<PlaceModel> places = [];
  List<ExpenseModel> expenses = [];
  List<PhotoModel> photos = [];
  AppSettings settings = AppSettings.defaults();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> deletePhoto(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).collection('memories').doc(id).delete();
      } catch (e) {
        debugPrint('[Wandr] Firestore photo delete error: $e');
      }
    }
    photos.removeWhere((p) => p.id == id);
    for (final trip in trips) {
      trip.photos?.removeWhere((p) => p.id == id);
    }
    await saveToDisk();
    notifyListeners();
  }

  void updateCurrency(String symbol) {
    currentCurrency = symbol;
    settings.currency = symbol;
    saveToDisk();
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).collection('trips').doc(id).delete();
      } catch (e) {
        debugPrint('[Wandr] Firestore trip delete error: $e');
      }
    }
    trips.removeWhere((t) => t.id == id);
    photos.removeWhere((p) => p.tripId == id);
    await saveToDisk();
    notifyListeners();
  }

  static const List<String> availableCurrencies = [
    r'$', r'€', r'₹', r'£', r'¥', r'₩', r'A$', r'C$', r'CHF', r'HK$', r'NZ$', r'S$', r'₺', r'₽', r'R$', r'฿', r'₫', r'₱', r'zł', r'Kč', r'Ft', r'₪', r'RM', r'Rs', r'Ksh', r'₵', r'₦', r'₡', r'RD$', r'J$', r'Q', r'B/.', r'₭'
  ];

  void loginDemo() {
    currentUser = UserModel(id: '1', name: 'Alex', email: 'alex@wandr.com', password: 'password123');
  }

  /// Syncs data with Firestore if a user is logged in.
  Future<void> syncWithCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      if (currentUser != null) {
        await userDoc.set(currentUser!.toJson(), SetOptions(merge: true));
      }
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        String finalUrl = photo.url;
        if (!photo.url.startsWith('http')) {
          finalUrl = await _uploadImage(photo.url, 'memories/${photo.id}');
          if (finalUrl.startsWith('http')) {
            photos[i] = photo.copyWith(url: finalUrl);
          } else {
            continue;
          }
        }
        await userDoc.collection('memories').doc(photo.id).set(photos[i].toJson());
      }
      for (int i = 0; i < trips.length; i++) {
        final trip = trips[i];
        String coverUrl = trip.coverPhoto ?? '';
        if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
          coverUrl = await _uploadImage(coverUrl, 'trips/${trip.id}/cover');
          if (coverUrl.startsWith('http')) {
            trips[i] = trip.copyWith(coverPhoto: coverUrl);
          }
        }
        if (trips[i].photos != null) {
          final tripPhotos = trips[i].photos!;
          for (int j = 0; j < tripPhotos.length; j++) {
            final p = tripPhotos[j];
            if (!p.url.startsWith('http')) {
              final remoteUrl = await _uploadImage(p.url, 'trips/${trip.id}/photos/${p.id}');
              if (remoteUrl.startsWith('http')) {
                tripPhotos[j] = p.copyWith(url: remoteUrl);
              }
            }
          }
        }
        await userDoc.collection('trips').doc(trip.id).set(trips[i].toJson());
      }
      debugPrint('[Wandr] Cloud sync completed.');
    } catch (e) {
      debugPrint('[Wandr] Cloud sync error: $e');
    }
  }

  Future<String> _uploadImage(String localPath, String remotePath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return localPath;
      final ref = _storage.ref().child(remotePath);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Wandr] Upload error: $e');
      return localPath;
    }
  }

  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ensure settings are loaded FIRST so Dark Mode persists on restart.
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        settings = AppSettings.fromJson(jsonDecode(settingsJson));
        currentCurrency = settings.currency;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userSnap = await userDocRef.get();
        if (userSnap.exists) {
          currentUser = UserModel.fromJson(userSnap.data()!);
        }
        final tripsSnap = await userDocRef.collection('trips').get();
        if (tripsSnap.docs.isNotEmpty) {
          final List<TripModel> loaded = tripsSnap.docs.map((doc) => TripModel.fromJson(doc.data())).toList();
          final Map<String, TripModel> uniqueMap = {};
          for (var t in loaded) { uniqueMap[t.id] = t; }
          trips = uniqueMap.values.toList();
        }
        final memoriesSnap = await userDocRef.collection('memories').get();
        if (memoriesSnap.docs.isNotEmpty) {
          photos = memoriesSnap.docs.map((doc) => PhotoModel.fromJson(doc.data())).toList();
        }
        if (currentUser != null || trips.isNotEmpty || photos.isNotEmpty) {
          await saveToDisk(skipCloud: true);
          return;
        }
      }
      final hasSavedData = prefs.getBool(_hasDataKey) ?? false;
      if (!hasSavedData && user == null) {
        trips = [...dummyTrips];
        await prefs.setBool(_hasDataKey, true);
        return;
      }
      final tripsJson = prefs.getString(_tripsKey);
      if (tripsJson != null) {
        final List<dynamic> decoded = jsonDecode(tripsJson);
        final List<TripModel> loaded = decoded.map((t) => TripModel.fromJson(t)).toList();
        final Map<String, TripModel> uniqueMap = {};
        for (var t in loaded) { uniqueMap[t.id] = t; }
        trips = uniqueMap.values.toList();
      }
      final photosJson = prefs.getString(_photosKey);
      if (photosJson != null) {
        final List<dynamic> decoded = jsonDecode(photosJson);
        photos = decoded.map((p) => PhotoModel.fromJson(p)).toList();
      }
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        currentUser = UserModel.fromJson(jsonDecode(userJson));
      }

    } catch (e) {
      debugPrint('[Wandr] Load error: $e');
      trips = [...dummyTrips];
    }
    notifyListeners();
  }

  Future<void> saveToDisk({bool skipCloud = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tripsKey, jsonEncode(trips.map((t) => t.toJson()).toList()));
      await prefs.setString(_photosKey, jsonEncode(photos.map((p) => p.toJson()).toList()));
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
      if (currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(currentUser!.toJson()));
      }
      await prefs.setBool(_hasDataKey, true);
      if (!skipCloud) {
        syncWithCloud();
      }
    } catch (e) {
      debugPrint('[Wandr] Save error: $e');
    }
    notifyListeners();
  }

  Future<void> resetData() async {
    currentUser = null;
    trips = [];
    photos = [];
    places = [];
    expenses = [];
    hasSeenOnboarding = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tripsKey);
    await prefs.remove(_photosKey);
    await prefs.remove(_hasDataKey);
    await prefs.remove('has_seen_onboarding');
    notifyListeners();
  }

  Future<void> addTrip(TripModel trip) async {
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      trips[index] = trip;
    } else {
      trips.insert(0, trip);
    }
    await saveToDisk();
    notifyListeners();
  }
}
