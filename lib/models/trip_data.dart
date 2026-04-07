// ignore_for_file: experimental_member_api
import 'package:isar/isar.dart';

part 'trip_data.g.dart';

@collection
class TripData {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String tripId;

  late String title;
  late String destination;
  late DateTime startDate;
  late DateTime endDate;
  String? coverImage;
  late String status; // 'upcoming', 'past'
  
  double totalBudget = 0.0;
  double spentBudget = 0.0;

  final itinerary = IsarLinks<DayData>();
  final photos = IsarLinks<PhotoData>();
  final expenses = IsarLinks<ExpenseData>();
}

@collection
class DayData {
  Id id = Isar.autoIncrement;
  late DateTime date;
  final places = IsarLinks<PlaceData>();
}

@collection
class PlaceData {
  Id id = Isar.autoIncrement;
  late String name;
  late String time;
  late String type;
  String? notes;
  double? lat;
  double? lng;
}

@collection
class ExpenseData {
  Id id = Isar.autoIncrement;
  late String name;
  late double amount;
  late String category;
  late DateTime date;
}

@collection
class PhotoData {
  Id id = Isar.autoIncrement;
  late String url;
  late String caption;
  late DateTime date;
  String? tripId;
}
