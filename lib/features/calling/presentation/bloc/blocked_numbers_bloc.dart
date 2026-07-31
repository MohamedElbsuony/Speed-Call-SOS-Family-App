import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/blocked_number_model.dart';
import '../../domain/repositories/blocked_numbers_repository.dart';

// Events
abstract class BlockedNumbersEvent extends Equatable {
  const BlockedNumbersEvent();
  @override
  List<Object?> get props => [];
}

class LoadBlockedNumbersEvent extends BlockedNumbersEvent {}

class BlockNumberEvent extends BlockedNumbersEvent {
  final BlockedNumberModel blockedNumber;
  const BlockNumberEvent(this.blockedNumber);
  @override
  List<Object?> get props => [blockedNumber];
}

class UnblockNumberEvent extends BlockedNumbersEvent {
  final String id;
  const UnblockNumberEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// States
class BlockedNumbersState extends Equatable {
  final List<BlockedNumberModel> blockedNumbers;
  final bool isLoading;

  const BlockedNumbersState({
    this.blockedNumbers = const [],
    this.isLoading = false,
  });

  BlockedNumbersState copyWith({
    List<BlockedNumberModel>? blockedNumbers,
    bool? isLoading,
  }) {
    return BlockedNumbersState(
      blockedNumbers: blockedNumbers ?? this.blockedNumbers,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [blockedNumbers, isLoading];
}

// Bloc
class BlockedNumbersBloc extends Bloc<BlockedNumbersEvent, BlockedNumbersState> {
  final BlockedNumbersRepository blockedNumbersRepository;

  BlockedNumbersBloc({required this.blockedNumbersRepository})
      : super(const BlockedNumbersState()) {
    on<LoadBlockedNumbersEvent>(_onLoad);
    on<BlockNumberEvent>(_onBlock);
    on<UnblockNumberEvent>(_onUnblock);
  }

  Future<void> _onLoad(LoadBlockedNumbersEvent event, Emitter<BlockedNumbersState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await blockedNumbersRepository.getBlockedNumbers();
      emit(state.copyWith(blockedNumbers: list, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onBlock(BlockNumberEvent event, Emitter<BlockedNumbersState> emit) async {
    await blockedNumbersRepository.blockNumber(event.blockedNumber);
    add(LoadBlockedNumbersEvent());
  }

  Future<void> _onUnblock(UnblockNumberEvent event, Emitter<BlockedNumbersState> emit) async {
    await blockedNumbersRepository.unblockNumber(event.id);
    add(LoadBlockedNumbersEvent());
  }
}
