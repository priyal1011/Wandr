import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_models.dart';

final mockTripsProvider = Provider<List<Trip>>((ref) {
  return [
    Trip(
      id: 'trip-1',
      title: 'Summer in Japan',
      destination: 'Japan',
      startDate: DateTime(2026, 7, 10),
      endDate: DateTime(2026, 7, 24),
      coverImage: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=2670&auto=format&fit=crop',
      status: 'upcoming',
      budget: Budget(
        total: 5000,
        spent: 1250,
        expenses: [
          Expense(
            id: 'exp-1',
            name: 'Flights',
            amount: 1200,
            category: 'transport',
            date: DateTime(2026, 4, 15),
          ),
          Expense(
            id: 'exp-2',
            name: 'Train Pass (Deposit)',
            amount: 50,
            category: 'transport',
            date: DateTime(2026, 5, 20),
          ),
        ],
      ),
      itinerary: [
        Day(
          id: 'day-1',
          date: DateTime(2026, 7, 10),
          places: const [
            Place(
              id: 'pl-1',
              name: 'Arrive at Narita Airport',
              time: '14:00',
              type: 'transport',
            ),
            Place(
              id: 'pl-2',
              name: 'Shinjuku Gyoen National Garden',
              time: '16:00',
              type: 'activity',
            ),
            Place(
              id: 'pl-3',
              name: 'Ichiran Ramen',
              time: '19:00',
              type: 'restaurant',
            ),
          ],
        ),
      ],
      photos: [
        Photo(
          id: 'ph-1',
          url: 'https://images.unsplash.com/photo-1542051812871-75868a473f98?auto=format&fit=crop&w=800&q=80',
          caption: 'Cherry blossoms',
          date: DateTime(2026, 7, 10),
        ),
      ],
    ),
    Trip(
      id: 'trip-2',
      title: 'Weekend in Paris',
      destination: 'Paris, France',
      startDate: DateTime(2026, 5, 12),
      endDate: DateTime(2026, 5, 15),
      coverImage: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=2920&auto=format&fit=crop',
      status: 'upcoming',
      budget: const Budget(
        total: 1500,
        spent: 400,
        expenses: [],
      ),
      itinerary: [],
      photos: [],
    ),
    Trip(
      id: 'trip-3',
      title: 'Tech Conference 2023',
      destination: 'San Francisco, USA',
      startDate: DateTime(2023, 10, 5),
      endDate: DateTime(2023, 10, 9),
      coverImage: 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?q=80&w=2832&auto=format&fit=crop',
      status: 'past',
      budget: const Budget(
        total: 3000,
        spent: 2800,
        expenses: [],
      ),
      itinerary: [],
      photos: [],
    ),
  ];
});

final upcomingTripsProvider = Provider<List<Trip>>((ref) {
  final trips = ref.watch(mockTripsProvider);
  return trips.where((t) => t.status == 'upcoming' || t.status == 'ongoing').toList();
});

final pastTripsProvider = Provider<List<Trip>>((ref) {
  final trips = ref.watch(mockTripsProvider);
  return trips.where((t) => t.status == 'past').toList();
});
