import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/permission_banner.dart';
import '../../../calling/presentation/bloc/calling_bloc.dart';
import '../../domain/models/contact_model.dart';
import '../bloc/contacts_bloc.dart';
import '../widgets/phone_number_picker_dialog.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ContactsBloc>().add(const LoadContactsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PermissionBanner(),
        Expanded(
          child: BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              if (state is ContactsLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ContactsLoadedState) {
                final favList = <ContactModel>[];
                final set = <String>{};
                for (var c in [...state.pinned, ...state.favorites]) {
                  if (set.add(c.id)) {
                    favList.add(c);
                  }
                }

                if (favList.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.star_border_rounded,
                    title: 'لا يوجد جهات اتصال مفضلة حالياً',
                    message: 'اضغط على زر الإضافة أدناه واضغط على النجمة ⭐ بجانب أي اسم لإضافته للمفضلة!',
                    buttonText: 'إضافة جهة اتصال للمفضلة',
                    onButtonPressed: () async {
                      await context.push('/contacts');
                      if (context.mounted) {
                        context.read<ContactsBloc>().add(const LoadContactsEvent());
                      }
                    },
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: favList.length,
                  itemBuilder: (context, index) {
                    final contact = favList[index];
                    return _buildFavoriteGridCard(context, contact, theme);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteGridCard(BuildContext context, ContactModel contact, ThemeData theme) {
    final initial = contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?';
    final primaryPhone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                    tooltip: 'إزالة من المفضلة',
                    onPressed: () {
                      context.read<ContactsBloc>().add(ToggleFavoriteContactEvent(contact.id));
                    },
                  ),
                ],
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contact.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                primaryPhone,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
