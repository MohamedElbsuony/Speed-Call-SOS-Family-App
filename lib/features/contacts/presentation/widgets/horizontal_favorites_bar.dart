import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../calling/presentation/bloc/calling_bloc.dart';
import '../../domain/models/contact_model.dart';
import '../bloc/contacts_bloc.dart';
import 'phone_number_picker_dialog.dart';

class HorizontalFavoritesBar extends StatelessWidget {
  const HorizontalFavoritesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        List<ContactModel> quickList = [];
        if (state is ContactsLoadedState) {
          final set = <String>{};
          for (var c in [...state.pinned, ...state.favorites]) {
            if (set.add(c.id)) {
              quickList.add(c);
            }
          }
          if (quickList.isEmpty && state.contacts.isNotEmpty) {
            quickList = state.contacts.take(6).toList();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.get('favorites'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/contacts'),
                    child: Text(loc.get('contacts')),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: quickList.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddFavoriteChip(context, theme, loc);
                  }

                  final contact = quickList[index - 1];
                  return _buildContactChip(context, contact, theme);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddFavoriteChip(BuildContext context, ThemeData theme, AppLocalizations loc) {
    return GestureDetector(
      onTap: () => context.push('/contacts'),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person_add_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.get('create_widget'),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(BuildContext context, ContactModel contact, ThemeData theme) {
    final initial = contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?';

    return GestureDetector(
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

        if (context.mounted) {
          context.read<CallingBloc>().add(
                TriggerDirectCallEvent(
                  phoneNumber: selectedPhone.number,
                  contactName: contact.displayName,
                ),
              );
        }
      },
      child: Column(
        children: [
          Badge(
            isLabelVisible: contact.isPinned,
            label: const Icon(Icons.push_pin, size: 10, color: Colors.white),
            backgroundColor: theme.colorScheme.primary,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              contact.displayName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
