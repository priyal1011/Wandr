import 'package:isar/isar.dart';
import '../../models/trip_data.dart';
import '../../models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  final Isar isar;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  SyncService(this.isar);

  Future<void> syncUser() async {
    final user = auth.currentUser;
    if (user == null) return;

    // Get local user data
    final localUser = await isar.userDatas.filter().uidEqualTo(user.uid).findFirst();
    if (localUser == null) return;

    // Push to Firestore
    await firestore.collection('users').doc(user.uid).set({
      'name': localUser.name,
      'email': localUser.email,
      'darkMode': localUser.darkMode,
      'hasSeenOnboarding': localUser.hasSeenOnboarding,
      'avatarUrl': localUser.avatarUrl,
    }, SetOptions(merge: true));
  }

  Future<void> syncTrips() async {
    final user = auth.currentUser;
    if (user == null) return;

    final localTrips = await isar.tripDatas.where().findAll();

    for (var trip in localTrips) {
      await firestore.collection('users').doc(user.uid).collection('trips').doc(trip.tripId).set({
        'title': trip.title,
        'destination': trip.destination,
        'startDate': trip.startDate.toIso8601String(),
        'endDate': trip.endDate.toIso8601String(),
        'status': trip.status,
        'totalBudget': trip.totalBudget,
        'spentBudget': trip.spentBudget,
        'coverImage': trip.coverImage,
      });
    }
  }

  // More complex sync for itinerary, expenses, and photos would go here
  // typically involving a timestamp-based "last sync" check.
}
