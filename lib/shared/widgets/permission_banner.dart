import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/localization/app_localizations.dart';

class PermissionBanner extends StatefulWidget {
  const PermissionBanner({super.key});

  @override
  State<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<PermissionBanner> {
  bool _hasCallPermission = true;
  bool _hasContactsPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final callStatus = await Permission.phone.status;
    final contactsStatus = await Permission.contacts.status;
    if (mounted) {
      setState(() {
        _hasCallPermission = callStatus.isGranted;
        _hasContactsPermission = contactsStatus.isGranted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.phone,
      Permission.contacts,
    ].request();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCallPermission && _hasContactsPermission) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.get('permissions'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_hasCallPermission)
            Text(
              loc.get('permission_call_desc'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          if (!_hasContactsPermission) ...[
            const SizedBox(height: 4),
            Text(
              loc.get('permission_contacts_desc'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _requestPermissions,
              child: Text(loc.get('grant_permission')),
            ),
          ),
        ],
      ),
    );
  }
}
