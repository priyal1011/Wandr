import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

abstract class TripState {}
class TripInitial extends TripState {}
class TripLoading extends TripState {}
class TripLoaded extends TripState {
  final TripModel trip;
  TripLoaded(this.trip);
}
class TripError extends TripState {
  final String message;
  TripError(this.message);
}

class TripCubit extends Cubit<TripState> {
  TripCubit() : super(TripInitial());

  void loadTrip(String id) {
    final store = getIt<InMemoryStore>();
    final trip = store.trips.firstWhere((t) => t.id == id, orElse: () => throw Exception('Trip not found'));
    emit(TripLoaded(trip));
  }
}