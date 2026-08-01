import '../models/contact_model.dart';

abstract class ContactsRepository {
  Future<List<ContactModel>> getContacts({String query = '', bool forceRefresh = false});
  Future<List<ContactModel>> getFavoriteContacts();
  Future<List<ContactModel>> getPinnedContacts();
  Future<void> togglePinContact(String contactId);
  Future<void> toggleFavoriteContact(String contactId);
}
