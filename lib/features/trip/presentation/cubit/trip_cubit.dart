import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../models/day_data.dart';
import '../../../../models/expense_model.dart';
import '../../../../models/photo_model.dart';
import 'trip_state.dart';

class TripCubit extends Cubit<TripState> {
  final String tripId;
  final InMemoryStore _store = getIt<InMemoryStore>();

  TripCubit(this.tripId) : super(TripInitial());

  Future<void> loadTrip() async {
    emit(TripLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final trip = _store.trips.where((t) => t.id == tripId).firstOrNull ?? 
                   (_store.trips.isNotEmpty ? _store.trips.first : null);
      
      if (trip != null) {
        emit(TripLoaded(trip));
      } else {
        emit(const TripError('Trip not found. It might have been deleted.'));
      }
    } catch (e) {
      emit(const TripError('Failed to load trip details.'));
    }
  }

  void updateTabIndex(int index) {
    if (state is TripLoaded) {
      emit((state as TripLoaded).copyWith(activeTabIndex: index));
    }
  }

  void updateItinerary(List<DayData> data) {
    if (state is TripLoaded) {
      final trip = (state as TripLoaded).trip;
      trip.itinerary = data;
      _store.saveToDisk();
      emit((state as TripLoaded).copyWith(trip: trip));
    }
  }

  void updateExpenses(List<ExpenseModel> data) {
    if (state is TripLoaded) {
      final trip = (state as TripLoaded).trip;
      trip.expenses = data;
      _store.saveToDisk();
      emit((state as TripLoaded).copyWith(trip: trip));
    }
  }

  void updatePhotos(List<PhotoModel> data) {
    if (state is TripLoaded) {
      final trip = (state as TripLoaded).trip;
      trip.photos = data;
      
      // Update global memories as well
      for (final p in data) {
        if (!_store.photos.every((gp) => gp.id != p.id)) {
           // Skip if already exists or update it
           final idx = _store.photos.indexWhere((gp) => gp.id == p.id);
           if (idx != -1) {
             _store.photos[idx] = p;
           }
        } else {
           _store.photos.add(p);
        }
      }
      
      _store.saveToDisk();
      emit((state as TripLoaded).copyWith(trip: trip));
    }
  }

  Future<void> deleteTrip() async {
    try {
      await _store.deleteTrip(tripId);
      emit(TripDeleted());
    } catch (e) {
      emit(const TripError('Failed to delete trip.'));
    }
  }

  void refreshFromStore() {
    if (state is TripLoaded) {
      final freshTrip = _store.trips.where((t) => t.id == tripId).firstOrNull;
      if (freshTrip != null) {
        emit((state as TripLoaded).copyWith(trip: freshTrip));
      }
    }
  }
}