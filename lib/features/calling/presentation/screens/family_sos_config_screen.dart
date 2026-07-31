import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    final updated = _config.copyWith(sosMessageText: _messageController.text);
    context.read<FamilySosBloc>().add(UpdateFamilySosConfigEvent(updated));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات طوارئ العائلة بنجاح')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت إضافة $displayName ($fullPhone) لأرقام الطوارئ')),
        );
      }
    }
  }

  void _addEmergencyNumber() {
    final countryCodeController = TextEditingController(text: '+20');
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهة اتصال للطوارئ'),
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
                label: const Text('اختيار من جهات الاتصال المسجلة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('أو كتابة الاسم والرقم يدوياً', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم جهة الاتصال (مثال: أمي / أخي)',
                  border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'الكود',
                        hintText: '+20',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: '1507366570',
                        border: OutlineInputBorder(),
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
            child: const Text('إلغاء'),
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
                  const SnackBar(content: Text('يرجى إدخال رقم الهاتف')),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _selectPrimaryCallContact() {
    final parsedList = _config.emergencyContacts.map((raw) => EmergencyContactItem.fromRaw(raw)).toList();

    if (parsedList.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('لا يوجد جهات طوارئ بعد'),
            ],
          ),
          content: const Text(
            'يرجى إضافة جهات اتصال للطوارئ أولاً في القائمة أدناه، ثم اختر أي منها ليكون الرقم الرئيسي للاتصال المباشر.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسناً'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _addEmergencyNumber();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة جهة طوارئ الآن'),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'اختر الرقم الرئيسي للاتصال المباشر عند الطوارئ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                label: const Text('إضافة جهة اتصال جديدة واختيارها'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinInstructionsDialog(bool isAutoSupported) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.widgets_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(isAutoSupported ? 'تثبيت ودجت الطوارئ' : 'إضافة ودجت الطوارئ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAutoSupported
                  ? 'تم طلب نافذة التثبيت التلقائي! اضغط "إضافة تلقائياً" في نافذة الموبايل.'
                  : 'لإضافة ودجت طوارئ العائلة إلى شاشتك الرئيسية:',
            ),
            const SizedBox(height: 12),
            const Text('1. اخرج لشاشة الموبايل الرئيسية.'),
            const Text('2. اضغط ضغطة مطولة على أي مكان فارغ.'),
            const Text('3. اختر الودجتس (Widgets) -> ابحث عن "الاتصال السريع".'),
            const Text('4. اسحب ودجت "طوارئ العائلة" ضعها على الشاشة.'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('فهمت ذلك'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emergencyItems = _config.emergencyContacts.map((raw) => EmergencyContactItem.fromRaw(raw)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('طوارئ العائلة (Family SOS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: BlocListener<FamilySosBloc, FamilySosState>(
        listenWhen: (previous, current) => previous.pinResult != current.pinResult,
        listener: (context, state) {
          if (state.pinResult != null) {
            _showPinInstructionsDialog(state.pinResult!);
          }
        },
        child: BlocBuilder<FamilySosBloc, FamilySosState>(
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
                      title: const Text('تفعيل نظام طوارئ العائلة', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('عرض ودجت الطوارئ على الشاشة الخارجية وزر الاستغاثة السريع في التطبيق'),
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
                  _buildSectionHeader(theme, 'نوع إجراء الطوارئ المفضل (Action Mode)'),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<int>(
                          value: 0,
                          groupValue: _config.sosActionMode,
                          title: const Text('مكالمة هاتفية فقط (Voice Call Only)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('الاتصال المباشر برقم الطوارئ الرئيسي فوراً دون فتح أي تطبيق آخر'),
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
                          title: const Text('رسالة واتساب فقط (WhatsApp Only)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('إرسال نصوص الاستغاثة والموقع الجغرافي عبر الواتساب لجميع الأرقام'),
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
                          title: const Text('رسالة نصية SMS مباشرة فقط (Offline Direct SMS Only)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('إرسال SMS نصي مباشر من شريحة الهاتف بدون الحاجة لإنترنت إطلاقاً'),
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
                  _buildSectionHeader(theme, 'جهة الاتصال الرئيسية عند الاتصال المباشر'),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: const Icon(Icons.contact_phone_rounded),
                      ),
                      title: Text(
                        _config.primaryCallNumber.isNotEmpty
                            ? _config.primaryCallName
                            : 'اختر جهة الاتصال الرئيسية (الزوج/الزوجة/الأب)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _config.primaryCallNumber.isNotEmpty
                            ? _config.primaryCallNumber
                            : 'سيتم الاتصال بها مباشرة فور ضغط ودجت أو زر الطوارئ',
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
                      _buildSectionHeader(theme, 'جهات اتصال الطوارئ (${emergencyItems.length})'),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _addEmergencyNumber,
                      ),
                    ],
                  ),

                  if (emergencyItems.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('لم يتم إضافة أي أرقام طوارئ بعد. اضغط + للإضافة.')),
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
                            subtitle: Text('${item.phone} • يستقبل تنبيهات الاستغاثة'),
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
                  _buildSectionHeader(theme, 'نص رسالة الاستغاثة المخصصة'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'اكتب نص رسالة الطوارئ...',
                          border: OutlineInputBorder(),
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
                    label: const Text('تثبيت ودجت طوارئ العائلة بالشاشة الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
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
