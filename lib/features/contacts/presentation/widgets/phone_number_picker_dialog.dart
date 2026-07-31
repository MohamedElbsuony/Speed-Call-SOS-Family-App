import 'package:flutter/material.dart';

import '../../domain/models/contact_model.dart';

class PhoneNumberPickerDialog extends StatelessWidget {
  final ContactModel contact;
  final ValueChanged<PhoneEntry> onSelected;

  const PhoneNumberPickerDialog({
    super.key,
    required this.contact,
    required this.onSelected,
  });

  static Future<PhoneEntry?> show(BuildContext context, ContactModel contact) {
    return showModalBottomSheet<PhoneEntry>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PhoneNumberPickerDialog(
        contact: contact,
        onSelected: (entry) => Navigator.of(context).pop(entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              contact.displayName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Select number to associate with this widget',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: contact.phones.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final phone = contact.phones[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        _getIconForLabel(phone.label),
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(phone.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(phone.label),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => onSelected(phone),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'work':
        return Icons.work_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'main':
        return Icons.star_rounded;
      default:
        return Icons.phone_android_rounded;
    }
  }
}
