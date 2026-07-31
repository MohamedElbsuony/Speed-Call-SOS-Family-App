import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/widget_config_model.dart';
import '../../domain/repositories/widget_repository.dart';

// Events
abstract class WidgetConfigEvent extends Equatable {
  const WidgetConfigEvent();
  @override
  List<Object?> get props => [];
}

class InitWidgetConfigEvent extends WidgetConfigEvent {
  final WidgetConfigModel? initialConfig;
  const InitWidgetConfigEvent(this.initialConfig);
  @override
  List<Object?> get props => [initialConfig];
}

class UpdateConfigFieldEvent extends WidgetConfigEvent {
  final WidgetConfigModel updatedConfig;
  const UpdateConfigFieldEvent(this.updatedConfig);
  @override
  List<Object?> get props => [updatedConfig];
}

class SaveWidgetConfigEvent extends WidgetConfigEvent {}

// States
class WidgetConfigState extends Equatable {
  final WidgetConfigModel config;
  final bool isSaving;
  final bool isSuccess;
  final String? errorMessage;

  const WidgetConfigState({
    required this.config,
    this.isSaving = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  WidgetConfigState copyWith({
    WidgetConfigModel? config,
    bool? isSaving,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return WidgetConfigState(
      config: config ?? this.config,
      isSaving: isSaving ?? this.isSaving,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [config, isSaving, isSuccess, errorMessage];
}

// Bloc
class WidgetConfigBloc extends Bloc<WidgetConfigEvent, WidgetConfigState> {
  final WidgetRepository widgetRepository;

  WidgetConfigBloc({required this.widgetRepository})
      : super(WidgetConfigState(
          config: WidgetConfigModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            widgetId: -1,
            contactId: '',
            contactName: 'Select Contact',
            phoneNumber: '',
            createdAt: DateTime.now(),
          ),
        )) {
    on<InitWidgetConfigEvent>(_onInit);
    on<UpdateConfigFieldEvent>(_onUpdate);
    on<SaveWidgetConfigEvent>(_onSave);
  }

  void _onInit(InitWidgetConfigEvent event, Emitter<WidgetConfigState> emit) {
    if (event.initialConfig != null) {
      emit(state.copyWith(config: event.initialConfig));
    }
  }

  void _onUpdate(UpdateConfigFieldEvent event, Emitter<WidgetConfigState> emit) {
    emit(state.copyWith(config: event.updatedConfig));
  }

  Future<void> _onSave(SaveWidgetConfigEvent event, Emitter<WidgetConfigState> emit) async {
    emit(state.copyWith(isSaving: true, isSuccess: false));
    try {
      await widgetRepository.saveWidget(state.config);
      await widgetRepository.pinWidgetToLauncher(state.config);
      emit(state.copyWith(isSaving: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }
}
