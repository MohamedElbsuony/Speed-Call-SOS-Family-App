import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/native/sim_info_platform.dart';
import '../../../../core/utils/t9_search_helper.dart';
import '../../../contacts/domain/models/contact_model.dart';
import '../../../contacts/presentation/bloc/contacts_bloc.dart';
import '../../../widgets/domain/models/widget_config_model.dart';
import '../../domain/models/speed_dial_key_model.dart';
import '../bloc/calling_bloc.dart';
import '../bloc/speed_dial_bloc.dart';
import 'emergency_services_bar.dart';
import 'sim_selection_sheet.dart';

class DialerKeypadView extends StatefulWidget {
  const DialerKeypadView({super.key});

  @override
  State<DialerKeypadView> createState() => _DialerKeypadViewState();
}

class _DialerKeypadViewState extends State<DialerKeypadView> {
  final TextEditingController _phoneController = TextEditingController();
  List<SimCardInfo> _availableSims = [];

  String get _inputBuffer => _phoneController.text;

  final Map<int, String> _subtextMap = {
    1: 'oo',
    2: 'ABC',
    3: 'DEF',
    4: 'GHI',
    5: 'JKL',
    6: 'MNO',
    7: 'PQRS',
    8: 'TUV',
    9: 'WXYZ',
    0: '+',
  };

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSimCardsInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSimCardsInfo() async {
    try {
      final sims = await SimInfoPlatform.getAvailableSims();
      if (mounted) {
        setState(() {
          _availableSims = sims;
        });
      }
    } catch (_) {}
  }

  void _playKeySound(String digit) {
    try {
      const channel = MethodChannel('com.speedcall.app/direct_call');
      channel.invokeMethod('playDtmfTone', {'digit': digit});
      Feedback.forTap(context);
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void _onKeyPress(String val) {
    _playKeySound(val);
    final text = _phoneController.text;
    final selection = _phoneController.selection;

    int start = selection.start >= 0 ? selection.start : text.length;
    int end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, val);
    final newIndex = start + val.length;

    _phoneController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newIndex),
    );
  }

  void _onBackspace() {
    _playKeySound('*');
    final text = _phoneController.text;
    if (text.isEmpty) return;

    final selection = _phoneController.selection;
    int start = selection.start >= 0 ? selection.start : text.length;
    int end = selection.end >= 0 ? selection.end : text.length;

    if (start == end && start > 0) {
      start = start - 1;
    }

    if (start < end) {
      final newText = text.replaceRange(start, end, '');
      _phoneController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    }
  }

  void _clearInputBuffer() {
    _playKeySound('#');
    _phoneController.clear();
  }

  void _saveTypedNumberAsNewContact() async {
    if (_inputBuffer.isEmpty) return;
    try {
      const channel = MethodChannel('com.speedcall.app/direct_call');
      final bool? success = await channel.invokeMethod<bool>('insertContact', {'phoneNumber': _inputBuffer});
      if (success != true) {
        final newContact = Contact(phones: [Phone(_inputBuffer)]);
        await FlutterContacts.openExternalInsert(newContact);
      }
    } catch (_) {
      try {
        final newContact = Contact(phones: [Phone(_inputBuffer)]);
        await FlutterContacts.openExternalInsert(newContact);
      } catch (_) {}
    }
  }

  void _assignTypedNumberToSpeedDial() {
    if (_inputBuffer.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'اختر رقم الزر (1-9) لتعيين الرقم إليه:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(9, (index) {
                final digit = index + 1;
                return ChoiceChip(
                  label: Text('زر #$digit', style: const TextStyle(fontWeight: FontWeight.bold)),
                  selected: false,
                  onSelected: (_) async {
                    Navigator.of(ctx).pop();
                    final simMode = await SimSelectionSheet.show(context) ?? 0;
                    final speedKey = SpeedDialKeyModel(
                      keyDigit: digit,
                      contactId: 'custom_$_inputBuffer',
                      contactName: _inputBuffer,
                      phoneNumber: _inputBuffer,
                      phoneLabel: 'Mobile',
                      simSelectionMode: simMode,
                    );
                    if (mounted) {
                      context.read<SpeedDialBloc>().add(AssignSpeedDialKeyEvent(speedKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تعيين الرقم $_inputBuffer للزر #$digit')),
                      );
                    }
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createWidgetForTypedNumber() {
    if (_inputBuffer.isEmpty) return;
    final config = WidgetConfigModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      widgetId: -1,
      contactId: 'custom_$_inputBuffer',
      contactName: _inputBuffer,
      phoneNumber: _inputBuffer,
      createdAt: DateTime.now(),
    );
    context.push('/widget-config', extra: config);
  }

  void _onLongPressDigit(int digit) async {
    _playKeySound(digit.toString());
    final speedDialState = context.read<SpeedDialBloc>().state;
    final assigned = speedDialState.speedDialKeys[digit];

    if (assigned != null && assigned.phoneNumber.isNotEmpty) {
      context.read<CallingBloc>().add(
            TriggerDirectCallEvent(
              phoneNumber: assigned.phoneNumber,
              contactName: assigned.contactName,
              simSelectionMode: assigned.simSelectionMode,
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${assigned.contactName} (${_getSimLabel(assigned.simSelectionMode)})...'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _assignNewContactToKey(digit);
    }
  }

  void _assignNewContactToKey(int digit) async {
    final result = await context.push<Map<String, dynamic>>('/contacts?select=true');
    if (result != null && mounted) {
      final ContactModel contact = result['contact'] as ContactModel;
      final PhoneEntry phone = result['phone'] as PhoneEntry;

      final simMode = await SimSelectionSheet.show(context) ?? 0;

      final newSpeedDial = SpeedDialKeyModel(
        keyDigit: digit,
        contactId: contact.id,
        contactName: contact.displayName,
        phoneNumber: phone.number,
        phoneLabel: phone.label,
        simSelectionMode: simMode,
      );

      if (context.mounted) {
        context.read<SpeedDialBloc>().add(AssignSpeedDialKeyEvent(newSpeedDial));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Key #$digit assigned to ${contact.displayName} (${_getSimLabel(simMode)})')),
        );
      }
    }
  }

  String _getSimLabel(int mode) {
    switch (mode) {
      case 1:
        return 'SIM 1';
      case 2:
        return 'SIM 2';
      case 3:
        return 'Ask';
      default:
        return 'Default SIM';
    }
  }

  void _triggerCallWithSim(int simMode, int? subId) {
    if (_inputBuffer.isEmpty) return;
    _playKeySound('0');
    context.read<CallingBloc>().add(
          TriggerDirectCallEvent(
            phoneNumber: _inputBuffer,
            contactName: _inputBuffer,
            simSelectionMode: simMode,
            subscriptionId: subId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocBuilder<ContactsBloc, ContactsState>(
        builder: (context, contactsState) {
          List<ContactModel> t9Matches = [];
          if (_inputBuffer.length >= 4 && contactsState is ContactsLoadedState) {
            t9Matches = T9SearchHelper.filterContactsByT9(contactsState.contacts, _inputBuffer);
          }

          return BlocBuilder<SpeedDialBloc, SpeedDialState>(
            builder: (context, speedState) {
              return Column(
                children: [
                  const EmergencyServicesBar(),

                  // Number Display & Quick Actions Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _phoneController,
                            readOnly: true,
                            showCursor: true,
                            enableInteractiveSelection: true,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: theme.colorScheme.primary,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Sleek Action Bar for Typed Number (Fixed Height Container)
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _inputBuffer.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.person_add_rounded, size: 18),
                                            tooltip: 'حفظ كجهة اتصال',
                                            onPressed: _saveTypedNumberAsNewContact,
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.touch_app_rounded, size: 18),
                                            tooltip: 'تعيين لاتصال سريع',
                                            onPressed: _assignTypedNumberToSpeedDial,
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.widgets_rounded, size: 18),
                                            tooltip: 'إنشاء ودجت',
                                            onPressed: _createWidgetForTypedNumber,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      'Hold 1-9 for Direct Speed Call',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // T9 Smart Search Results Carousel (Fixed Reserved Height)
                  SizedBox(
                    height: 50,
                    child: t9Matches.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: t9Matches.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final contact = t9Matches[index];
                                final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

                                return ActionChip(
                                  avatar: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      contact.displayName.isNotEmpty ? contact.displayName[0] : '?',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  label: Text('${contact.displayName} ($phone)'),
                                  onPressed: () {
                                    _playKeySound('0');
                                    context.read<CallingBloc>().add(
                                          TriggerDirectCallEvent(
                                            phoneNumber: phone,
                                            contactName: contact.displayName,
                                          ),
                                        );
                                  },
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const Divider(height: 1, indent: 24, endIndent: 24),
                  const SizedBox(height: 8),

                  // Keypad Grid - Strictly LTR (Balanced Vertical Spacing)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRow(['1', '2', '3'], speedState, theme),
                          const SizedBox(height: 6),
                          _buildRow(['4', '5', '6'], speedState, theme),
                          const SizedBox(height: 6),
                          _buildRow(['7', '8', '9'], speedState, theme),
                          const SizedBox(height: 6),
                          _buildRow(['*', '0', '#'], speedState, theme),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Call Controls (Premium Dual SIM Gradient Dock + Backspace)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        // Left alignment balance spacer
                        const SizedBox(width: 50),

                        // Premium SIM 1 Call Button (Emerald Gradient)
                        _buildSimCallButton(
                          label: loc.get('sim_1'),
                          carrierName: _availableSims.isNotEmpty ? _availableSims[0].carrierName : '',
                          gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
                          onTap: _inputBuffer.isNotEmpty
                              ? () => _triggerCallWithSim(
                                    1,
                                    _availableSims.isNotEmpty ? _availableSims[0].subscriptionId : 1,
                                  )
                              : null,
                          theme: theme,
                        ),

                        const SizedBox(width: 10),

                        // Premium SIM 2 Call Button (Royal Blue Gradient)
                        _buildSimCallButton(
                          label: loc.get('sim_2'),
                          carrierName: _availableSims.length >= 2 ? _availableSims[1].carrierName : '',
                          gradientColors: const [Color(0xFF2563EB), Color(0xFF06B6D4)],
                          onTap: _inputBuffer.isNotEmpty
                              ? () => _triggerCallWithSim(
                                    2,
                                    _availableSims.length >= 2 ? _availableSims[1].subscriptionId : 2,
                                  )
                              : null,
                          theme: theme,
                        ),

                        const SizedBox(width: 10),

                        // Backspace Clear Button (Enlarged)
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: _inputBuffer.isNotEmpty
                              ? InkWell(
                                  onTap: _onBackspace,
                                  onLongPress: _clearInputBuffer,
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.backspace_rounded,
                                      size: 26,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSimCallButton({
    required String label,
    required String carrierName,
    required List<Color> gradientColors,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final bool isEnabled = onTap != null;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: isEnabled
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isEnabled ? Colors.white.withValues(alpha: 0.25) : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.call_rounded,
                      size: 18,
                      color: isEnabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isEnabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (carrierName.isNotEmpty && carrierName != label)
                          Text(
                            carrierName,
                            style: TextStyle(
                              fontSize: 10,
                              color: isEnabled ? Colors.white.withValues(alpha: 0.85) : theme.colorScheme.onSurfaceVariant,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, SpeedDialState speedState, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((keyStr) {
        final digitInt = int.tryParse(keyStr);
        final speedKey = digitInt != null ? speedState.speedDialKeys[digitInt] : null;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: _buildDialKey(
              keyStr: keyStr,
              subtext: digitInt != null ? _subtextMap[digitInt] : null,
              assignedContact: speedKey?.contactName,
              onTap: () => _onKeyPress(keyStr),
              onLongPress: digitInt != null && digitInt >= 1 && digitInt <= 9
                  ? () => _onLongPressDigit(digitInt)
                  : null,
              theme: theme,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDialKey({
    required String keyStr,
    String? subtext,
    String? assignedContact,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required ThemeData theme,
  }) {
    final bool hasAssignedContact = assignedContact != null && assignedContact.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.18),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            border: Border.all(
              color: hasAssignedContact
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                keyStr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  height: 1.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (hasAssignedContact) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assignedContact,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (subtext != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
