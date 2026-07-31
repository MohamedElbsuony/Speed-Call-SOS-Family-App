import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/call_log_model.dart';
import '../../domain/repositories/calling_repository.dart';

// Events
abstract class CallingEvent extends Equatable {
  const CallingEvent();
  @override
  List<Object?> get props => [];
}

class LoadCallHistoryEvent extends CallingEvent {}

class TriggerDirectCallEvent extends CallingEvent {
  final String phoneNumber;
  final String contactName;
  final int simSelectionMode;
  final int? subscriptionId;

  const TriggerDirectCallEvent({
    required this.phoneNumber,
    required this.contactName,
    this.simSelectionMode = 0,
    this.subscriptionId,
  });

  @override
  List<Object?> get props => [phoneNumber, contactName, simSelectionMode, subscriptionId];
}

class ClearCallHistoryEvent extends CallingEvent {}

// States
abstract class CallingState extends Equatable {
  const CallingState();
  @override
  List<Object?> get props => [];
}

class CallingInitialState extends CallingState {}

class CallingLoadingState extends CallingState {}

class CallHistoryLoadedState extends CallingState {
  final List<CallLogModel> logs;
  const CallHistoryLoadedState(this.logs);
  @override
  List<Object?> get props => [logs];
}

class DirectCallResultState extends CallingState {
  final bool success;
  final String message;
  const DirectCallResultState({required this.success, required this.message});
  @override
  List<Object?> get props => [success, message];
}

// Bloc
class CallingBloc extends Bloc<CallingEvent, CallingState> {
  final CallingRepository callingRepository;

  CallingBloc({required this.callingRepository}) : super(CallingInitialState()) {
    on<LoadCallHistoryEvent>(_onLoadHistory);
    on<TriggerDirectCallEvent>(_onTriggerCall);
    on<ClearCallHistoryEvent>(_onClearHistory);
  }

  Future<void> _onLoadHistory(LoadCallHistoryEvent event, Emitter<CallingState> emit) async {
    emit(CallingLoadingState());
    try {
      final logs = await callingRepository.getCallHistory();
      emit(CallHistoryLoadedState(logs));
    } catch (e) {
      emit(CallHistoryLoadedState(const []));
    }
  }

  Future<void> _onTriggerCall(TriggerDirectCallEvent event, Emitter<CallingState> emit) async {
    final success = await callingRepository.makeCall(
      phoneNumber: event.phoneNumber,
      contactName: event.contactName,
      simSelectionMode: event.simSelectionMode,
      subscriptionId: event.subscriptionId,
    );

    if (success) {
      emit(const DirectCallResultState(success: true, message: 'Call placed successfully'));
    } else {
      emit(const DirectCallResultState(success: false, message: 'Failed to place direct call. Check permissions.'));
    }
    add(LoadCallHistoryEvent());
  }

  Future<void> _onClearHistory(ClearCallHistoryEvent event, Emitter<CallingState> emit) async {
    await callingRepository.clearCallHistory();
    add(LoadCallHistoryEvent());
  }
}
