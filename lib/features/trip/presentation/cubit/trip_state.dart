import 'package:equatable/equatable.dart';
import '../../../../models/trip_model.dart';

abstract class TripState extends Equatable {
  const TripState();
  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripLoaded extends TripState {
  final TripModel trip;
  final int activeTabIndex;

  const TripLoaded(this.trip, {this.activeTabIndex = 0});

  @override
  List<Object?> get props => [trip, activeTabIndex];

  TripLoaded copyWith({TripModel? trip, int? activeTabIndex}) {
    return TripLoaded(
      trip ?? this.trip,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

class TripError extends TripState {
  final String message;
  const TripError(this.message);
  @override
  List<Object?> get props => [message];
}

class TripDeleted extends TripState {}
