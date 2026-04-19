import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/day_data.dart';
import '../models/place_data.dart';
import '../models/place_model.dart';
import '../models/expense_model.dart';
import '../models/photo_model.dart';
import '../models/app_settings.dart';

// ─── Dummy data (used only on first launch) ───────────────

final List<TripModel> dummyTrips = [
  TripModel(
    id: '1',
    name: 'Kyoto Spring',
    destination: 'Kyoto, Japan',
    totalBudget: 4000,
    currency: r'$',
    coverPhoto: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
    startDate: DateTime.now().add(const Duration(days: 10)),
    endDate: DateTime.now().add(const Duration(days: 17)),
    itinerary: [
      DayData(
        date: DateTime.now().add(const Duration(days: 10)),
        places: [
          PlaceData(
            name: 'Fushimi Inari',
            time: '09:00 AM',
            type: 'Activity',
            notes: 'Wear comfortable walking shoes.',
          ),
          PlaceData(
            name: 'Nishiki Market',
            time: '12:30 PM',
            type: 'Food',
            notes: 'Try the tamagoyaki!',
          ),
        ],
      ),
    ],
  ),
  TripModel(
    id: '2',
    name: 'Alpine Escape',
    destination: 'Swiss Alps',
    startDate: DateTime.now().add(const Duration(days: 30)),
    endDate: DateTime.now().add(const Duration(days: 37)),
    totalBudget: 5500,
    currency: r'$',
    coverPhoto: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99',
  ),
  TripModel(
    id: '103',
    name: 'Santorini Sunset',
    destination: 'Santorini, Greece',
    startDate: DateTime.now().add(const Duration(days: 45)),
    endDate: DateTime.now().add(const Duration(days: 52)),
    totalBudget: 3200,
    currency: r'€',
    coverPhoto: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1',
  ),
  TripModel(
    id: '104',
    name: 'NYC Winter',
    destination: 'New York City, USA',
    startDate: DateTime.now().add(const Duration(days: 60)),
    endDate: DateTime.now().add(const Duration(days: 65)),
    totalBudget: 2800,
    currency: r'$',
    coverPhoto: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9',
  ),
  TripModel(
    id: '105',
    name: 'Bali Retreat',
    destination: 'Bali, Indonesia',
    startDate: DateTime.now().add(const Duration(days: 80)),
    endDate: DateTime.now().add(const Duration(days: 90)),
    totalBudget: 1500,
    currency: r'$',
    coverPhoto: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4',
  ),
  TripModel(
    id: '106',
    name: 'Iceland Drive',
    destination: 'Reykjavik, Iceland',
    startDate: DateTime.now().add(const Duration(days: 100)),
    endDate: DateTime.now().add(const Duration(days: 110)),
    totalBudget: 4500,
    currency: r'$',
    coverPhoto: 'https://images.unsplash.com/photo-1476610182048-b716b8518aae',
  ),
  TripModel(
    id: '107',
    name: 'Amazon Explore',
    destination: 'Manaus, Brazil',
    startDate: DateTime.now().add(const Duration(days: 150)),
    endDate: DateTime.now().add(const Duration(days: 160)),
    totalBudget: 2500,
    currency: r'$',
    coverPhoto: 'https://images.unsplash.com/photo-1518182170546-076616fd6cd5',
  ),
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
  bool _isSyncingCloud = false;

  bool get isSyncingCloud => _isSyncingCloud;

  Future<void> deletePhoto(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('memories')
            .doc(id)
            .delete();
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
    // 1. INSTANT MEMORY REMOVAL (No waiting)
    trips.removeWhere((t) => t.id == id);
    photos.removeWhere((p) => p.tripId == id);
    notifyListeners();

    // 2. ISOLATED BACKGROUND ZONE for Disk and Cloud
    unawaited(runZonedGuarded(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Fire and forget Firestore removal to avoid waiting on GMS report stats
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('trips')
              .doc(id)
              .delete()
              .timeout(const Duration(seconds: 5));
        }
        
        // Finalize disk cleanups in a silent zone
        await saveToDisk(skipCloud: true);
      } catch (e) {
        debugPrint('[Wandr] Isolated deletion background error intercepted: $e');
      }
    }, (error, stack) {
       debugPrint('[Wandr] Shielded Deletion caught exception: $error');
    })!);
  }

  static const List<String> availableCurrencies = [
    r'$',
    r'€',
    r'₹',
    r'£',
    r'¥',
    r'₩',
    r'A$',
    r'C$',
    r'CHF',
    r'HK$',
    r'NZ$',
    r'S$',
    r'₺',
    r'₽',
    r'R$',
    r'฿',
    r'₫',
    r'₱',
    r'zł',
    r'Kč',
    r'Ft',
    r'₪',
    r'RM',
    r'Rs',
    r'Ksh',
    r'₵',
    r'₦',
    r'₡',
    r'RD$',
    r'J$',
    r'Q',
    r'B/.',
    r'₭',
  ];

  void loginDemo() {
    currentUser = UserModel(
      id: '1',
      name: 'Alex',
      email: 'alex@wandr.com',
      password: 'password123',
    );
  }

  /// Syncs data with Firestore if a user is logged in.
  Future<void> syncWithCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isSyncingCloud) return;

    _isSyncingCloud = true;
    notifyListeners();
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
        await userDoc
            .collection('memories')
            .doc(photo.id)
            .set(photos[i].toJson());
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
              final remoteUrl = await _uploadImage(
                p.url,
                'trips/${trip.id}/photos/${p.id}',
              );
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
    } finally {
      _isSyncingCloud = false;
      notifyListeners();
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
          final List<TripModel> loaded = tripsSnap.docs
              .map((doc) => TripModel.fromJson(doc.data()))
              .toList();
          final Map<String, TripModel> uniqueMap = {};
          for (var t in loaded) {
            uniqueMap[t.id] = t;
          }
          trips = uniqueMap.values.toList();
        }
        final memoriesSnap = await userDocRef.collection('memories').get();
        if (memoriesSnap.docs.isNotEmpty) {
          photos = memoriesSnap.docs
              .map((doc) => PhotoModel.fromJson(doc.data()))
              .toList();
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
        final List<TripModel> loaded = decoded
            .map((t) => TripModel.fromJson(t))
            .toList();
        final Map<String, TripModel> uniqueMap = {};
        for (var t in loaded) {
          uniqueMap[t.id] = t;
        }
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
      await prefs.setString(
        _tripsKey,
        jsonEncode(trips.map((t) => t.toJson()).toList()),
      );
      await prefs.setString(
        _photosKey,
        jsonEncode(photos.map((p) => p.toJson()).toList()),
      );
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
    // 1. Instant reset for UI responsiveness
    currentUser = null;
    trips = [];
    photos = [];
    places = [];
    expenses = [];
    hasSeenOnboarding = false;
    notifyListeners();

    // 2. Silent background disk wipe in an isolated zone
    unawaited(runZonedGuarded(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tripsKey);
        await prefs.remove(_photosKey);
        await prefs.remove(_hasDataKey);
        await prefs.remove('has_seen_onboarding');
      } catch (e) {
        debugPrint('[Wandr] Isolated reset background error caught: $e');
      }
    }, (error, stack) {})!);
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
