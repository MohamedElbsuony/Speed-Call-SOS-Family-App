import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../contacts/domain/models/contact_model.dart';
import '../../domain/models/family_sos_config_model.dart';
import '../bloc/family_sos_bloc.dart';

class EmergencyContactItem {
  final String name;
  final String phone;

  EmergencyContactItem({required this.name, required this.phone});

  factory EmergencyContactItem.fromRaw(String raw) {
    if (raw.contains('|')) {
      final parts = raw.split('|');
      return EmergencyContactItem(
        name: parts[0].trim(),
        phone: parts.sublist(1).join('|').trim(),
      );
    }
    return EmergencyContactItem(name: raw.trim(), phone: raw.trim());
  }

  String toRaw() => name.isNotEmpty && name != phone ? '$name|$phone' : phone;
}

class FamilySosConfigScreen extends StatefulWidget {
  const FamilySosConfigScreen({super.key});

  @override
  State<FamilySosConfigScreen> createState() => _FamilySosConfigScreenState();
}

class _FamilySosConfigScreenState extends State<FamilySosConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _messageController;
  late FamilySosConfigModel _config;

  @override
  void initState() {
    super.initState();
    _config = context.read<FamilySosBloc>().state.config;
    _messageController = TextEditingController(text: _config.sosMessageText);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final loc = AppLocalizations.of(context);
    final updated = _config.copyWith(sosMessageText: _messageController.text);
    context.read<FamilySosBloc>().add(UpdateFamilySosConfigEvent(updated));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.get('sos_saved'))),
    );
  }

  void _pickEmergencyNumberFromContacts() async {
    final result = await context.push<Map<String, dynamic>>('/contacts?select=true');
    if (result != null && mounted) {
      final ContactModel contact = result['contact'] as ContactModel;
      final PhoneEntry phone = result['phone'] as PhoneEntry;
      final fullPhone = phone.number.trim();
      final displayName = contact.displayName.trim();

      if (fullPhone.isNotEmpty) {
        final item = EmergencyContactItem(name: displayName, phone: fullPhone);
        final newList = List<String>.from(_config.emergencyContacts)..add(item.toRaw());
        setState(() {
          _config = _config.copyWith(
            emergencyContacts: newList,
            primaryCallNumber: _config.primaryCallNumber.isEmpty ? fullPhone : _config.primaryCallNumber,
            primaryCallName: _config.primaryCallName.isEmpty ? displayName : _config.primaryCallName,
          );
        });
        _saveConfig();
      }
    }
  }

  void _addEmergencyNumber() {
    final loc = AppLocalizations.of(context);
    final countryCodeController = TextEditingController(text: '+20');
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.get('add_emergency_contact_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickEmergencyNumberFromContacts();
                },
                icon: const Icon(Icons.contacts_rounded, color: Colors.blue),
                label: Text(loc.get('pick_from_contacts_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(loc.get('or_type_manually'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: loc.get('contact_name_label'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: TextField(
                      controller: countryCodeController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: loc.get('country_code_label'),
                        hintText: '+20',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: loc.get('phone_number_label'),
                        hintText: '1507366570',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              var code = countryCodeController.text.trim();
              if (!code.startsWith('+')) code = '+$code';
              final number = phoneController.text.trim();
              final name = nameController.text.trim();

              if (number.isNotEmpty) {
                final fullPhone = '$code$number';
                final displayName = name.isNotEmpty ? name : fullPhone;
                final item = EmergencyContactItem(name: displayName, phone: fullPhone);
                final newList = List<String>.from(_config.emergencyContacts)..add(item.toRaw());
                setState(() {
                  _config = _config.copyWith(
                    emergencyContacts: newList,
                    primaryCallNumber: _config.primaryCallNumber.isEmpty ? fullPhone : _config.primaryCallNumber,
                    primaryCallName: _config.primaryCallName.isEmpty ? displayName : _config.primaryCallName,
                  );
                });
                _saveConfig();
                Navigator.of(ctx).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.get('phone_number_label'))),
                );
              }
            },
            child: Text(loc.get('add')),
          ),
        ],
      ),
    );
  }

  void _selectPrimaryCallContact() {
    final loc = AppLocalizations.of(context);
    final parsedList = _config.emergencyContacts.map((raw) => EmergencyContactItem.fromRaw(raw)).toList();

    if (parsedList.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(loc.get('no_emergency_contacts_dialog_title')),
            ],
          ),
          content: Text(loc.get('no_emergency_contacts_dialog_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.get('got_it')),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _addEmergencyNumber();
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(loc.get('add_emergency_contact_now')),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                loc.get('select_primary_modal_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: parsedList.length,
                itemBuilder: (context, index) {
                  final item = parsedList[index];
                  final isSelected = _config.primaryCallNumber == item.phone;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.red : Colors.grey.shade200,
                      child: Icon(
                        Icons.call_rounded,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.phone),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.red) : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _config = _config.copyWith(
                          primaryCallNumber: item.phone,
                          primaryCallName: item.name,
                        );
                      });
                      _saveConfig();
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickEmergencyNumberFromContacts();
                },
                icon: const Icon(Icons.person_add_rounded),
                label: Text(loc.get('add_new_contact_and_select')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final emergencyItems = _config.emergencyContacts.map((raw) => EmergencyContactItem.fromRaw(raw)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('family_sos_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: BlocBuilder<FamilySosBloc, FamilySosState>(
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Master Enable Card
                Card(
                  color: _config.isEnabled ? theme.colorScheme.errorContainer.withValues(alpha: 0.3) : null,
                  child: SwitchListTile(
                    title: Text(loc.get('enable_family_sos'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(loc.get('enable_family_sos_sub')),
                    value: _config.isEnabled,
                    onChanged: (val) {
                      setState(() {
                        _config = _config.copyWith(isEnabled: val);
                      });
                      _saveConfig();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Dedicated Emergency Action Mode Selection
                _buildSectionHeader(theme, loc.get('sos_action_mode')),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        value: 0,
                        groupValue: _config.sosActionMode,
                        title: Text(loc.get('mode_call_only'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(loc.get('mode_call_only_sub')),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _config = _config.copyWith(sosActionMode: val);
                            });
                            _saveConfig();
                          }
                        },
                      ),
                      RadioListTile<int>(
                        value: 1,
                        groupValue: _config.sosActionMode,
                        title: Text(loc.get('mode_wa_only'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(loc.get('mode_wa_only_sub')),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _config = _config.copyWith(sosActionMode: val);
                            });
                            _saveConfig();
                          }
                        },
                      ),
                      RadioListTile<int>(
                        value: 2,
                        groupValue: _config.sosActionMode,
                        title: Text(loc.get('mode_sms_only'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(loc.get('mode_sms_only_sub')),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _config = _config.copyWith(sosActionMode: val);
                            });
                            _saveConfig();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Primary Emergency Direct Call Target
                _buildSectionHeader(theme, loc.get('primary_target_header')),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.contact_phone_rounded),
                    ),
                    title: Text(
                      _config.primaryCallNumber.isNotEmpty
                          ? _config.primaryCallName
                          : loc.get('select_primary_target'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _config.primaryCallNumber.isNotEmpty
                          ? _config.primaryCallNumber
                          : loc.get('primary_target_sub'),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _selectPrimaryCallContact,
                  ),
                ),

                const SizedBox(height: 20),

                // Emergency Contacts List (WhatsApp / SMS Alerts)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(theme, '${loc.get('emergency_contacts_count')} (${emergencyItems.length})'),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: _addEmergencyNumber,
                    ),
                  ],
                ),

                if (emergencyItems.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text(loc.get('no_emergency_contacts'))),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: emergencyItems.map((item) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.phone} • ${loc.get('receives_sos_alerts')}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () {
                              final newList = List<String>.from(_config.emergencyContacts)..remove(item.toRaw());
                              setState(() {
                                _config = _config.copyWith(emergencyContacts: newList);
                              });
                              _saveConfig();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 20),

                // SOS Message Customization
                _buildSectionHeader(theme, loc.get('custom_sos_message')),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: loc.get('sos_message_hint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Pin SOS AppWidget Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    context.read<FamilySosBloc>().add(PinFamilySosWidgetEvent());
                  },
                  icon: const Icon(Icons.add_to_home_screen_rounded),
                  label: Text(loc.get('pin_sos_widget_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
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
}
