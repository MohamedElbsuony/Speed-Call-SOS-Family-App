import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/speed_dial_key_model.dart';
import '../../domain/repositories/speed_dial_repository.dart';

// Events
abstract class SpeedDialEvent extends Equatable {
  const SpeedDialEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpeedDialKeysEvent extends SpeedDialEvent {}

class AssignSpeedDialKeyEvent extends SpeedDialEvent {
  final SpeedDialKeyModel speedDialKey;
  const AssignSpeedDialKeyEvent(this.speedDialKey);
  @override
  List<Object?> get props => [speedDialKey];
}

class RemoveSpeedDialKeyEvent extends SpeedDialEvent {
  final int keyDigit;
  const RemoveSpeedDialKeyEvent(this.keyDigit);
  @override
  List<Object?> get props => [keyDigit];
}

// States
class SpeedDialState extends Equatable {
  final Map<int, SpeedDialKeyModel> speedDialKeys;
  final bool isLoading;

  const SpeedDialState({
    this.speedDialKeys = const {},
    this.isLoading = false,
  });

  SpeedDialState copyWith({
    Map<int, SpeedDialKeyModel>? speedDialKeys,
    bool? isLoading,
  }) {
    return SpeedDialState(
      speedDialKeys: speedDialKeys ?? this.speedDialKeys,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [speedDialKeys, isLoading];
}

// Bloc
class SpeedDialBloc extends Bloc<SpeedDialEvent, SpeedDialState> {
  final SpeedDialRepository speedDialRepository;

  SpeedDialBloc({required this.speedDialRepository}) : super(const SpeedDialState()) {
    on<LoadSpeedDialKeysEvent>(_onLoad);
    on<AssignSpeedDialKeyEvent>(_onAssign);
    on<RemoveSpeedDialKeyEvent>(_onRemove);
  }

  Future<void> _onLoad(LoadSpeedDialKeysEvent event, Emitter<SpeedDialState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final keysMap = await speedDialRepository.getSpeedDialKeys();
      emit(state.copyWith(speedDialKeys: keysMap, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onAssign(AssignSpeedDialKeyEvent event, Emitter<SpeedDialState> emit) async {
    await speedDialRepository.assignSpeedDialKey(event.speedDialKey);
    add(LoadSpeedDialKeysEvent());
  }

  Future<void> _onRemove(RemoveSpeedDialKeyEvent event, Emitter<SpeedDialState> emit) async {
    await speedDialRepository.removeSpeedDialKey(event.keyDigit);
    add(LoadSpeedDialKeysEvent());
  }
}
