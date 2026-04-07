import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import 'package:equatable/equatable.dart';

abstract class TripsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TripsInitial extends TripsState {}

class TripsLoading extends TripsState {}

class TripsLoaded extends TripsState {
  final List<TripModel> upcomingTrips;
  final List<TripModel> pastTrips;
  final int tripsCompleted;
  final int placesVisited;
  final int totalPhotos;
  final String userName;

  TripsLoaded({
    required this.upcomingTrips,
    required this.pastTrips,
    required this.tripsCompleted,
    required this.placesVisited,
    required this.totalPhotos,
    required this.userName,
  });

  @override
  List<Object?> get props => [
        upcomingTrips,
        pastTrips,
        tripsCompleted,
        placesVisited,
        totalPhotos,
        userName,
      ];
}

class TripsError extends TripsState {
  final String message;
  TripsError(this.message);

  @override
  List<Object?> get props => [message];
}

class TripsCubit extends Cubit<TripsState> {
  TripsCubit() : super(TripsInitial());

  void loadTrips({String query = '', String sortOption = 'date_newest'}) async {
    emit(TripsLoading());

    // Artificial delay to make it feel responsive but smooth
    await Future.delayed(const Duration(milliseconds: 300)); 

    try {
      final store = getIt<InMemoryStore>();
      final allTrips = store.trips;
      final now = DateTime.now();

      // Computations
      final pastTripsCount = allTrips.where((t) => t.endDate.isBefore(now)).length;
      final placesVisitedCount = store.places.length;
      final totalPhotosCount = store.photos.length;

      // Filter
      final q = query.toLowerCase();
      var filteredTrips = allTrips.where((t) {
        return t.name.toLowerCase().contains(q) || t.destination.toLowerCase().contains(q);
      }).toList();

      // Sort
      if (sortOption == 'date_newest') {
        filteredTrips.sort((a, b) => b.startDate.compareTo(a.startDate));
      } else if (sortOption == 'date_oldest') {
        filteredTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
      } else if (sortOption == 'dest_az') {
        filteredTrips.sort((a, b) => a.destination.compareTo(b.destination));
      }

      final upcoming = filteredTrips.where((t) => !t.endDate.isBefore(now)).toList();
      final past = filteredTrips.where((t) => t.endDate.isBefore(now)).toList();
      
      final userName = store.currentUser?.name ?? 'Explorer';

      emit(TripsLoaded(
        upcomingTrips: upcoming,
        pastTrips: past,
        tripsCompleted: pastTripsCount,
        placesVisited: placesVisitedCount,
        totalPhotos: totalPhotosCount,
        userName: userName,
      ));
    } catch (e) {
      emit(TripsError('Failed to load your adventures.'));
    }
  }

  void deleteTrip(String tripId) {
    if (state is TripsLoaded) {
      final store = getIt<InMemoryStore>();
      store.trips.removeWhere((t) => t.id == tripId);
      store.saveToDisk();
      
      loadTrips(); // Reload with defaults
    }
  }
}
