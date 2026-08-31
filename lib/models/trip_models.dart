class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String coverImage;
  final String status;
  final List<Day> itinerary;
  final List<Photo> photos;
  final Budget budget;

  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.coverImage,
    required this.status,
    required this.itinerary,
    required this.photos,
    required this.budget,
  });
}

class Day {
  final String id;
  final DateTime date;
  final List<Place> places;

  const Day({
    required this.id,
    required this.date,
    required this.places,
  });
}

class Place {
  final String id;
  final String name;
  final String time;
  final String type;
  final String? notes;
  final Location? location;

  const Place({
    required this.id,
    required this.name,
    required this.time,
    required this.type,
    this.notes,
    this.location,
  });
}

class Location {
  final double lat;
  final double lng;

  const Location({required this.lat, required this.lng});
}

class Budget {
  final double total;
  final double spent;
  final List<Expense> expenses;

  const Budget({
    required this.total,
    required this.spent,
    required this.expenses,
  });
}

class Expense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime date;

  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
  });
}

class Photo {
  final String id;
  final String url;
  final String caption;
  final DateTime date;

  const Photo({
    required this.id,
    required this.url,
    required this.caption,
    required this.date,
  });
}