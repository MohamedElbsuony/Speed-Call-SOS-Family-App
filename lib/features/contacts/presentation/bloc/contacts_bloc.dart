import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/contact_model.dart';
import '../../domain/repositories/contacts_repository.dart';

// Events
abstract class ContactsEvent extends Equatable {
  const ContactsEvent();
  @override
  List<Object?> get props => [];
}

class LoadContactsEvent extends ContactsEvent {
  final String query;
  final bool forceRefresh;
  const LoadContactsEvent({this.query = '', this.forceRefresh = false});
  @override
  List<Object?> get props => [query, forceRefresh];
}

class TogglePinContactEvent extends ContactsEvent {
  final String contactId;
  const TogglePinContactEvent(this.contactId);
  @override
  List<Object?> get props => [contactId];
}

class ToggleFavoriteContactEvent extends ContactsEvent {
  final String contactId;
  const ToggleFavoriteContactEvent(this.contactId);
  @override
  List<Object?> get props => [contactId];
}

// States
abstract class ContactsState extends Equatable {
  const ContactsState();
  @override
  List<Object?> get props => [];
}

class ContactsInitialState extends ContactsState {}

class ContactsLoadingState extends ContactsState {}

class ContactsLoadedState extends ContactsState {
  final List<ContactModel> contacts;
  final List<ContactModel> favorites;
  final List<ContactModel> pinned;
  final String searchQuery;

  const ContactsLoadedState({
    required this.contacts,
    required this.favorites,
    required this.pinned,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [contacts, favorites, pinned, searchQuery];
}

class ContactsErrorState extends ContactsState {
  final String message;
  const ContactsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository contactsRepository;

  ContactsBloc({required this.contactsRepository}) : super(ContactsInitialState()) {
    on<LoadContactsEvent>(_onLoadContacts);
    on<TogglePinContactEvent>(_onTogglePin);
    on<ToggleFavoriteContactEvent>(_onToggleFavorite);
  }

  Future<void> _onLoadContacts(LoadContactsEvent event, Emitter<ContactsState> emit) async {
    if (state is! ContactsLoadedState) {
      emit(ContactsLoadingState());
    }
    try {
      final contacts = await contactsRepository.getContacts(query: event.query);
      final favorites = contacts.where((c) => c.isFavorite).toList();
      final pinned = contacts.where((c) => c.isPinned).toList();

      emit(ContactsLoadedState(
        contacts: contacts,
        favorites: favorites,
        pinned: pinned,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(ContactsErrorState(e.toString()));
    }
  }

  Future<void> _onTogglePin(TogglePinContactEvent event, Emitter<ContactsState> emit) async {
    try {
      await contactsRepository.togglePinContact(event.contactId);
      final currentQuery = (state is ContactsLoadedState)
          ? (state as ContactsLoadedState).searchQuery
          : '';
      final contacts = await contactsRepository.getContacts(query: currentQuery);
      final favorites = contacts.where((c) => c.isFavorite).toList();
      final pinned = contacts.where((c) => c.isPinned).toList();

      emit(ContactsLoadedState(
        contacts: contacts,
        favorites: favorites,
        pinned: pinned,
        searchQuery: currentQuery,
      ));
    } catch (e) {
      emit(ContactsErrorState(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(ToggleFavoriteContactEvent event, Emitter<ContactsState> emit) async {
    try {
      await contactsRepository.toggleFavoriteContact(event.contactId);
      final currentQuery = (state is ContactsLoadedState)
          ? (state as ContactsLoadedState).searchQuery
          : '';
      final contacts = await contactsRepository.getContacts(query: currentQuery);
      final favorites = contacts.where((c) => c.isFavorite).toList();
      final pinned = contacts.where((c) => c.isPinned).toList();

      emit(ContactsLoadedState(
        contacts: contacts,
        favorites: favorites,
        pinned: pinned,
        searchQuery: currentQuery,
      ));
    } catch (e) {
      emit(ContactsErrorState(e.toString()));
    }
  }
}
