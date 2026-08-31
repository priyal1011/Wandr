import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/photo_model.dart';

mixin TripStore on ChangeNotifier {
  List<TripModel> trips = [];
  List<PhotoModel> photos = [];

  void setTrips(List<TripModel> newTrips) {
    trips = newTrips;
    notifyListeners();
  }

  void setPhotos(List<PhotoModel> newPhotos) {
    photos = newPhotos;
    notifyListeners();
  }
}
