import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/widget_config_model.dart';
import '../../domain/repositories/widget_repository.dart';

// Events
abstract class WidgetListEvent extends Equatable {
  const WidgetListEvent();
  @override
  List<Object?> get props => [];
}

class LoadWidgetListEvent extends WidgetListEvent {}

class DeleteWidgetEvent extends WidgetListEvent {
  final String id;
  const DeleteWidgetEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class DuplicateWidgetEvent extends WidgetListEvent {
  final WidgetConfigModel config;
  const DuplicateWidgetEvent(this.config);
  @override
  List<Object?> get props => [config];
}

class PinWidgetToHomeScreenEvent extends WidgetListEvent {
  final WidgetConfigModel config;
  const PinWidgetToHomeScreenEvent(this.config);
  @override
  List<Object?> get props => [config];
}

// States
abstract class WidgetListState extends Equatable {
  const WidgetListState();
  @override
  List<Object?> get props => [];
}

class WidgetListInitialState extends WidgetListState {}

class WidgetListLoadingState extends WidgetListState {}

class WidgetListLoadedState extends WidgetListState {
  final List<WidgetConfigModel> widgets;
  const WidgetListLoadedState(this.widgets);
  @override
  List<Object?> get props => [widgets];
}

class WidgetListErrorState extends WidgetListState {
  final String message;
  const WidgetListErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class WidgetListBloc extends Bloc<WidgetListEvent, WidgetListState> {
  final WidgetRepository widgetRepository;

  WidgetListBloc({required this.widgetRepository}) : super(WidgetListInitialState()) {
    on<LoadWidgetListEvent>(_onLoadWidgets);
    on<DeleteWidgetEvent>(_onDeleteWidget);
    on<DuplicateWidgetEvent>(_onDuplicateWidget);
    on<PinWidgetToHomeScreenEvent>(_onPinWidget);
  }

  Future<void> _onLoadWidgets(LoadWidgetListEvent event, Emitter<WidgetListState> emit) async {
    emit(WidgetListLoadingState());
    try {
      final list = await widgetRepository.getAllWidgets();
      emit(WidgetListLoadedState(list));
    } catch (e) {
      emit(WidgetListErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteWidget(DeleteWidgetEvent event, Emitter<WidgetListState> emit) async {
    try {
      await widgetRepository.deleteWidget(event.id);
      add(LoadWidgetListEvent());
    } catch (e) {
      emit(WidgetListErrorState(e.toString()));
    }
  }

  Future<void> _onDuplicateWidget(DuplicateWidgetEvent event, Emitter<WidgetListState> emit) async {
    try {
      await widgetRepository.duplicateWidget(event.config);
      add(LoadWidgetListEvent());
    } catch (e) {
      emit(WidgetListErrorState(e.toString()));
    }
  }

  Future<void> _onPinWidget(PinWidgetToHomeScreenEvent event, Emitter<WidgetListState> emit) async {
    try {
      await widgetRepository.pinWidgetToLauncher(event.config);
    } catch (e) {
      // Pin error handled gracefully
    }
  }
}
