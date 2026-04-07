import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  void setPage(int index) => emit(index);

  void completeOnboarding() {
    getIt<InMemoryStore>().hasSeenOnboarding = true;
  }
}
