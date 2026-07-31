import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/permission_banner.dart';
import '../../domain/models/settings_model.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              const PermissionBanner(),
              const SizedBox(height: 12),

              // Category 1: Speed Dialing & Shortcuts
              _buildCategoryHeader(theme, Icons.flash_on_rounded, loc.get('cat_speed_dial'), Colors.amber),
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        child: const Icon(Icons.touch_app_rounded, color: Colors.amber),
                      ),
                      title: Text(loc.get('manage_speed_dial_keys'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(loc.get('manage_speed_dial_sub')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/speed-dial-manager'),
                    ),
                  ],
                ),
              ),

              // Category 2: Safety & Protection
              _buildCategoryHeader(theme, Icons.security_rounded, loc.get('cat_safety'), Colors.red),
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        child: const Icon(Icons.sos_rounded, color: Colors.red),
                      ),
                      title: Text(loc.get('family_sos'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(loc.get('family_sos_sub')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/family-sos'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.2),
                        child: Icon(Icons.block_rounded, color: theme.colorScheme.error),
                      ),
                      title: Text(loc.get('blocked_contacts'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(loc.get('blocked_contacts_sub')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/blocked-numbers'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                        child: Icon(Icons.insights_rounded, color: theme.colorScheme.tertiary),
                      ),
                      title: Text(loc.get('analytics'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(loc.get('analytics_sub')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/analytics'),
                    ),
                  ],
                ),
              ),

              // Category 3: Appearance & Language
              _buildCategoryHeader(theme, Icons.palette_rounded, loc.get('cat_appearance'), Colors.blue),
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(loc.get('theme'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    ),
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.system,
                      groupValue: settings.themeMode,
                      title: Text(loc.get('theme_system')),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(themeMode: val)));
                        }
                      },
                    ),
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.light,
                      groupValue: settings.themeMode,
                      title: Text(loc.get('theme_light')),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(themeMode: val)));
                        }
                      },
                    ),
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.dark,
                      groupValue: settings.themeMode,
                      title: Text(loc.get('theme_dark')),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(themeMode: val)));
                        }
                      },
                    ),
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.amoled,
                      groupValue: settings.themeMode,
                      title: Text(loc.get('theme_amoled')),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(themeMode: val)));
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(loc.get('language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    ),
                    RadioListTile<String>(
                      value: 'ar',
                      groupValue: settings.languageCode,
                      title: Text(loc.get('arabic')),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(languageCode: val)));
                        }
                      },
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      groupValue: settings.languageCode,
                      title: Text(loc.get('english')),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(languageCode: val)));
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Category 4: Calling Preferences
              _buildCategoryHeader(theme, Icons.tune_rounded, loc.get('cat_calling_prefs'), Colors.purple),
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(loc.get('vibration')),
                      subtitle: Text(loc.get('vibration_desc')),
                      value: settings.enableVibration,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(enableVibration: val)));
                      },
                    ),
                    SwitchListTile(
                      title: Text(loc.get('confirmation_dialog')),
                      subtitle: Text(loc.get('confirmation_desc')),
                      value: settings.enableCallConfirmation,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(enableCallConfirmation: val)));
                      },
                    ),
                  ],
                ),
              ),

              // Category 5: Developer & App Info
              _buildCategoryHeader(theme, Icons.info_outline_rounded, loc.get('cat_developer'), Colors.teal),
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.2),
                    child: const Text('MS', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(loc.get('about_developer'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(loc.get('about_developer_sub')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/about-developer'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
