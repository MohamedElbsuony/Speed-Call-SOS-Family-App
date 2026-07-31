import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/family_sos_config_model.dart';
import '../../domain/repositories/family_sos_repository.dart';

// Events
abstract class FamilySosEvent extends Equatable {
  const FamilySosEvent();
  @override
  List<Object?> get props => [];
}

class LoadFamilySosConfigEvent extends FamilySosEvent {}

class UpdateFamilySosConfigEvent extends FamilySosEvent {
  final FamilySosConfigModel config;
  const UpdateFamilySosConfigEvent(this.config);
  @override
  List<Object?> get props => [config];
}

class PinFamilySosWidgetEvent extends FamilySosEvent {}

class TriggerEmergencyAlertEvent extends FamilySosEvent {
  final FamilySosConfigModel? customConfig;
  const TriggerEmergencyAlertEvent({this.customConfig});
  @override
  List<Object?> get props => [customConfig];
}

// State
class FamilySosState extends Equatable {
  final FamilySosConfigModel config;
  final bool isLoading;
  final bool isTriggering;
  final bool? pinResult;

  const FamilySosState({
    this.config = const FamilySosConfigModel(),
    this.isLoading = false,
    this.isTriggering = false,
    this.pinResult,
  });

  FamilySosState copyWith({
    FamilySosConfigModel? config,
    bool? isLoading,
    bool? isTriggering,
    bool? pinResult,
  }) {
    return FamilySosState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isTriggering: isTriggering ?? this.isTriggering,
      pinResult: pinResult,
    );
  }

  @override
  List<Object?> get props => [config, isLoading, isTriggering, pinResult];
}

// BLoC
class FamilySosBloc extends Bloc<FamilySosEvent, FamilySosState> {
  final FamilySosRepository familySosRepository;

  FamilySosBloc({required this.familySosRepository}) : super(const FamilySosState()) {
    on<LoadFamilySosConfigEvent>(_onLoad);
    on<UpdateFamilySosConfigEvent>(_onUpdate);
    on<PinFamilySosWidgetEvent>(_onPinWidget);
    on<TriggerEmergencyAlertEvent>(_onTriggerAlert);
  }

  Future<void> _onLoad(LoadFamilySosConfigEvent event, Emitter<FamilySosState> emit) async {
    emit(state.copyWith(isLoading: true));
    final cfg = await familySosRepository.getFamilySosConfig();
    emit(state.copyWith(config: cfg, isLoading: false));
  }

  Future<void> _onUpdate(UpdateFamilySosConfigEvent event, Emitter<FamilySosState> emit) async {
    await familySosRepository.saveFamilySosConfig(event.config);
    emit(state.copyWith(config: event.config));
  }

  Future<void> _onPinWidget(PinFamilySosWidgetEvent event, Emitter<FamilySosState> emit) async {
    final success = await familySosRepository.pinSosWidgetToHomeScreen();
    emit(state.copyWith(pinResult: success));
  }

  Future<void> _onTriggerAlert(TriggerEmergencyAlertEvent event, Emitter<FamilySosState> emit) async {
    emit(state.copyWith(isTriggering: true));
    final targetConfig = event.customConfig ?? state.config;
    await familySosRepository.dispatchEmergencyAlert(targetConfig);
    emit(state.copyWith(isTriggering: false));
  }
}
