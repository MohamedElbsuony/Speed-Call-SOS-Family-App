import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../calling/presentation/bloc/calling_bloc.dart';
import '../../domain/models/contact_model.dart';
import '../bloc/contacts_bloc.dart';
import '../widgets/phone_number_picker_dialog.dart';

class ContactsScreen extends StatefulWidget {
  final bool isSelectingForWidget;

  const ContactsScreen({
    super.key,
    this.isSelectingForWidget = false,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ContactsBloc>().add(const LoadContactsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectingForWidget ? 'Select Contact for Speed Dial / Favorite' : loc.get('contacts')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<ContactsBloc>().add(LoadContactsEvent(query: query));
              },
              decoration: InputDecoration(
                hintText: loc.get('search_contacts'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ContactsBloc>().add(const LoadContactsEvent(query: ''));
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<ContactsBloc, ContactsState>(
        builder: (context, state) {
          if (state is ContactsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ContactsErrorState) {
            return Center(child: Text(state.message));
          }

          if (state is ContactsLoadedState) {
            if (state.contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search_rounded, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No contacts found', style: theme.textTheme.titleMedium),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (state.pinned.isNotEmpty && state.searchQuery.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      loc.get('pinned'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...state.pinned.map((c) => _buildContactTile(context, c)),
                  const Divider(indent: 16, endIndent: 16),
                ],
                if (state.favorites.isNotEmpty && state.searchQuery.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      loc.get('favorites'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...state.favorites.map((c) => _buildContactTile(context, c)),
                  const Divider(indent: 16, endIndent: 16),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    loc.get('contacts'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...state.contacts.map((c) => _buildContactTile(context, c)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, ContactModel contact) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(contact.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        contact.phones.isNotEmpty
            ? '${contact.phones.first.label}: ${contact.phones.first.number}'
            : 'No number',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              contact.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: contact.isPinned ? theme.colorScheme.primary : null,
              size: 20,
            ),
            onPressed: () {
              context.read<ContactsBloc>().add(TogglePinContactEvent(contact.id));
            },
          ),
          IconButton(
            icon: Icon(
              contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: contact.isFavorite ? Colors.amber[700] : null,
              size: 22,
            ),
            onPressed: () {
              context.read<ContactsBloc>().add(ToggleFavoriteContactEvent(contact.id));
              final actionStr = contact.isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة ⭐';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم $actionStr لـ ${contact.displayName}'), duration: const Duration(seconds: 1)),
              );
            },
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: () async {
        if (contact.phones.isEmpty) return;

        PhoneEntry selectedPhone;
        if (contact.phones.length > 1) {
          final chosen = await PhoneNumberPickerDialog.show(context, contact);
          if (chosen == null) return;
          selectedPhone = chosen;
        } else {
          selectedPhone = contact.phones.first;
        }

        if (widget.isSelectingForWidget) {
          if (context.mounted) {
            context.pop({
              'contact': contact,
              'phone': selectedPhone,
            });
          }
        } else {
          if (context.mounted) {
            context.read<CallingBloc>().add(
                  TriggerDirectCallEvent(
                    phoneNumber: selectedPhone.number,
                    contactName: contact.displayName,
                  ),
                );
          }
        }
      },
    );
  }
}
