import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/settings_model.dart';
import '../../domain/repositories/settings_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateSettingsEvent extends SettingsEvent {
  final SettingsModel settings;
  const UpdateSettingsEvent(this.settings);
  @override
  List<Object?> get props => [settings];
}

// States
class SettingsState extends Equatable {
  final SettingsModel settings;
  final bool isLoading;

  const SettingsState({
    this.settings = const SettingsModel(),
    this.isLoading = false,
  });

  SettingsState copyWith({
    SettingsModel? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsBloc({required this.settingsRepository}) : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final settings = await settingsRepository.getSettings();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onUpdateSettings(UpdateSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(settings: event.settings));
    await settingsRepository.saveSettings(event.settings);
  }
}
