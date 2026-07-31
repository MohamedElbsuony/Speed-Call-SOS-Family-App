import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/native/sim_info_platform.dart';

import '../../../contacts/domain/models/contact_model.dart';
import '../../domain/models/widget_config_model.dart';
import '../bloc/widget_config_bloc.dart';
import '../widgets/widget_preview_card.dart';

class WidgetConfigScreen extends StatefulWidget {
  final WidgetConfigModel? initialConfig;

  const WidgetConfigScreen({super.key, this.initialConfig});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  List<SimCardInfo> _availableSims = [];

  final List<int> _bgColorPresets = [
    0xFF1F1F2F,
    0xFF1E88E5,
    0xFFD81B60,
    0xFF43A047,
    0xFFFB8C00,
    0xFF6D4C41,
    0xFF000000,
    0xFFFFFFFF,
  ];

  final List<int> _textColorPresets = [
    0xFFFFFFFF,
    0xFF000000,
    0xFFFFEB3B,
    0xFF00E676,
    0xFF00E5FF,
  ];

  @override
  void initState() {
    super.initState();
    context.read<WidgetConfigBloc>().add(InitWidgetConfigEvent(widget.initialConfig));
    _fetchSims();
  }

  Future<void> _fetchSims() async {
    final sims = await SimInfoPlatform.getAvailableSims();
    if (mounted) {
      setState(() {
        _availableSims = sims;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialConfig != null ? loc.get('edit_widget') : loc.get('create_widget')),
        actions: [
          BlocBuilder<WidgetConfigBloc, WidgetConfigState>(
            builder: (context, state) {
              return TextButton.icon(
                onPressed: state.config.phoneNumber.isNotEmpty
                    ? () {
                        context.read<WidgetConfigBloc>().add(SaveWidgetConfigEvent());
                      }
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: Text(loc.get('pin_to_home')),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<WidgetConfigBloc, WidgetConfigState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Widget saved & requested for home screen!')),
            );
            context.pop();
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final config = state.config;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Live Widget Preview Header
              Card(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'Live Widget Preview',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      WidgetPreviewCard(config: config),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Step 1: Select Contact
              _buildSectionTitle(theme, loc.get('select_contact')),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person_add_rounded, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: Text(
                    config.contactName.isNotEmpty ? config.contactName : loc.get('select_contact'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    config.phoneNumber.isNotEmpty
                        ? '${config.phoneLabel}: ${config.phoneNumber}'
                        : 'Tap to choose contact & phone number',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final result = await context.push<Map<String, dynamic>>('/contacts?select=true');
                    if (result != null && mounted) {
                      final ContactModel contact = result['contact'] as ContactModel;
                      final PhoneEntry phone = result['phone'] as PhoneEntry;

                      final updated = config.copyWith(
                        contactId: contact.id,
                        contactName: contact.displayName,
                        phoneNumber: phone.number,
                        phoneLabel: phone.label,
                        photoPath: contact.photoPath,
                      );
                      if (context.mounted) {
                        context.read<WidgetConfigBloc>().add(UpdateConfigFieldEvent(updated));
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Step 2: SIM Card Preference
              _buildSectionTitle(theme, loc.get('sim_selection')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        value: 0,
                        groupValue: config.simSelectionMode,
                        title: Text(loc.get('sim_default')),
                        onChanged: (val) {
                          if (val != null) {
                            context
                                .read<WidgetConfigBloc>()
                                .add(UpdateConfigFieldEvent(config.copyWith(simSelectionMode: val)));
                          }
                        },
                      ),
                      RadioListTile<int>(
                        value: 1,
                        groupValue: config.simSelectionMode,
                        title: Text(_getSimTitle(1)),
                        onChanged: (val) {
                          if (val != null) {
                            context
                                .read<WidgetConfigBloc>()
                                .add(UpdateConfigFieldEvent(config.copyWith(simSelectionMode: val)));
                          }
                        },
                      ),
                      RadioListTile<int>(
                        value: 2,
                        groupValue: config.simSelectionMode,
                        title: Text(_getSimTitle(2)),
                        onChanged: (val) {
                          if (val != null) {
                            context
                                .read<WidgetConfigBloc>()
                                .add(UpdateConfigFieldEvent(config.copyWith(simSelectionMode: val)));
                          }
                        },
                      ),
                      RadioListTile<int>(
                        value: 3,
                        groupValue: config.simSelectionMode,
                        title: Text(loc.get('sim_ask')),
                        onChanged: (val) {
                          if (val != null) {
                            context
                                .read<WidgetConfigBloc>()
                                .add(UpdateConfigFieldEvent(config.copyWith(simSelectionMode: val)));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Step 3: Widget Size
              _buildSectionTitle(theme, loc.get('widget_size')),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'small', label: Text(loc.get('size_small'))),
                  ButtonSegment(value: 'medium', label: Text(loc.get('size_medium'))),
                  ButtonSegment(value: 'large', label: Text(loc.get('size_large'))),
                ],
                selected: {config.widgetSize},
                onSelectionChanged: (set) {
                  context
                      .read<WidgetConfigBloc>()
                      .add(UpdateConfigFieldEvent(config.copyWith(widgetSize: set.first)));
                },
              ),

              const SizedBox(height: 20),

              // Step 4: Appearance Customization
              _buildSectionTitle(theme, loc.get('appearance')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.get('image_shape'), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'circular', label: Text(loc.get('circular'))),
                          ButtonSegment(value: 'rounded', label: Text(loc.get('rounded'))),
                          ButtonSegment(value: 'square', label: Text(loc.get('square'))),
                        ],
                        selected: {config.imageShape},
                        onSelectionChanged: (set) {
                          context
                              .read<WidgetConfigBloc>()
                              .add(UpdateConfigFieldEvent(config.copyWith(imageShape: set.first)));
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(loc.get('background_color'), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _bgColorPresets.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final colorInt = _bgColorPresets[index];
                            final isSelected = config.backgroundColor == colorInt;
                            return GestureDetector(
                              onTap: () {
                                context.read<WidgetConfigBloc>().add(
                                      UpdateConfigFieldEvent(config.copyWith(backgroundColor: colorInt)),
                                    );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(colorInt),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: colorInt == 0xFFFFFFFF ? Colors.black : Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(loc.get('text_color'), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _textColorPresets.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final colorInt = _textColorPresets[index];
                            final isSelected = config.textColor == colorInt;
                            return GestureDetector(
                              onTap: () {
                                context.read<WidgetConfigBloc>().add(
                                      UpdateConfigFieldEvent(config.copyWith(textColor: colorInt)),
                                    );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(colorInt),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: colorInt == 0xFFFFFFFF ? Colors.black : Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text(loc.get('border_radius'))),
                          Text('${config.borderRadius.toInt()} px'),
                        ],
                      ),
                      Slider(
                        value: config.borderRadius,
                        min: 0,
                        max: 32,
                        divisions: 16,
                        onChanged: (val) {
                          context
                              .read<WidgetConfigBloc>()
                              .add(UpdateConfigFieldEvent(config.copyWith(borderRadius: val)));
                        },
                      ),
                      SwitchListTile(
                        title: Text(loc.get('show_name')),
                        value: config.showName,
                        onChanged: (val) {
                          context
                              .read<WidgetConfigBloc>()
                              .add(UpdateConfigFieldEvent(config.copyWith(showName: val)));
                        },
                      ),
                      SwitchListTile(
                        title: Text(loc.get('show_phone')),
                        value: config.showPhone,
                        onChanged: (val) {
                          context
                              .read<WidgetConfigBloc>()
                              .add(UpdateConfigFieldEvent(config.copyWith(showPhone: val)));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: config.phoneNumber.isNotEmpty
                    ? () {
                        context.read<WidgetConfigBloc>().add(SaveWidgetConfigEvent());
                      }
                    : null,
                icon: const Icon(Icons.add_to_home_screen_rounded),
                label: Text(loc.get('pin_to_home')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getSimTitle(int slot) {
    final loc = AppLocalizations.of(context);
    final matches = _availableSims.where((s) => s.slotIndex == (slot - 1));
    if (matches.isNotEmpty) {
      final sim = matches.first;
      return 'Always ${sim.displayName} (${sim.carrierName})';
    }
    return slot == 1 ? loc.get('sim_1') : loc.get('sim_2');
  }
}
