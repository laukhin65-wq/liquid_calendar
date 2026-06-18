import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/repeat_type.dart';
import '../data/models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../data/models/event_category.dart';
import '../data/models/reminder_offset.dart';
import '../data/models/location_model.dart';
import '../widgets/glass.dart';
import 'location_search_screen.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? initialDate;
  final CalendarEvent? editEvent;
  final int initialTabIndex;

  const AddEventScreen({
    super.key,
    this.initialDate,
    this.editEvent,
    this.initialTabIndex = 0,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  // 3 вкладки: Мероприятие, Задача, День рождения
  final List<String> topTabs = ['Мероприятие', 'Задача', 'День рождения'];
  int activeTabIndex = 0;

  late DateTime startDate;
  late DateTime endDate;
  DateTime? dueDate; // «Срок» для задачи
  double? locationLatitude;
  double? locationLongitude;

  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

  bool isAllDay = false;

  RepeatType repeatType = RepeatType.none;
  EventCategory category = EventCategory.personal;
  ReminderOffset reminder = ReminderOffset.none;

  // Часовой пояс мероприятия. По умолчанию — системный.
  // Храним смещение в минутах от UTC; null = «как в системе».
  final int deviceTzOffset = DateTime.now().timeZoneOffset.inMinutes;
  final String deviceTzName = DateTime.now().timeZoneName; // системное обозначение
  late int tzOffsetMinutes = deviceTzOffset;

  // Новые поля
  int selectedColor = 0; // 0 = цвет по умолчанию (из категории)
  final List<String> contacts = [];
  final Map<String, String> contactPhones = {}; // имя контакта -> номер для набора
  final List<String> attachments = []; // пути; показываем имена

  // Напоминания для дня рождения: список (дни до события, время).
  final List<_BirthdayReminder> birthdayReminders = [];

  bool get _isEditing => widget.editEvent != null;

  @override
  void initState() {
    super.initState();
    activeTabIndex = widget.initialTabIndex;
    final edit = widget.editEvent;
    if (edit != null) {
      // Режим редактирования — заполняем из существующего события
      titleController.text = edit.title;
      locationController.text = edit.location ?? '';
      descriptionController.text = edit.description ?? '';
      startDate = edit.start;
      endDate = edit.end;
      startTime = TimeOfDay(hour: edit.start.hour, minute: edit.start.minute);
      endTime = TimeOfDay(hour: edit.end.hour, minute: edit.end.minute);
      repeatType = edit.repeatType;
      category = edit.category;
      reminder = ReminderOffsetX.fromMinutes(edit.reminderMinutes);
      // Если цвет не задан кастомно — берём цвет категории
      selectedColor = edit.color != 0 ? edit.color : category.color.toARGB32();
      if (edit.contacts != null) contacts.addAll(edit.contacts!);
      if (edit.attachments != null) attachments.addAll(edit.attachments!);
      if (edit.timeZoneOffset != null) tzOffsetMinutes = edit.timeZoneOffset!;
      isAllDay = edit.start.hour == 0 && edit.start.minute == 0 &&
          edit.end.hour == 23 && edit.end.minute == 59;

      // Загружаем напоминания дня рождения
      if (edit.birthdayReminders != null && edit.birthdayReminders!.isNotEmpty) {
        for (final part in edit.birthdayReminders!.split('|')) {
          final bits = part.split(':');
          if (bits.length == 3) {
            birthdayReminders.add(_BirthdayReminder(
              daysBefore: int.parse(bits[0]),
              time: TimeOfDay(hour: int.parse(bits[1]), minute: int.parse(bits[2])),
            ));
          }
        }
      }
      dueDate = edit.dueDate;

      // Определяем вкладку по категории
      if (category == EventCategory.birthday) {
        activeTabIndex = 2;
      } else if (category == EventCategory.task) {
        activeTabIndex = 1;
      } else {
        activeTabIndex = 0;
      }
    } else {
      final baseDate = widget.initialDate ?? context.read<CalendarProvider>().selectedDate;
      startDate = baseDate;
      endDate = baseDate;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  static const List<String> _ruMonthsGen = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  // День рождения отображается без года (повторяется ежегодно)
  String _formatDayMonth(DateTime date) =>
      '${date.day} ${_ruMonthsGen[date.month - 1]}';

  String _formatOffset(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    return m == 0
        ? 'GMT$sign$h'
        : 'GMT$sign$h:${m.toString().padLeft(2, '0')}';
  }

  // Подпись часового пояса. Для системного добавляем системное обозначение.
  String _tzLabel() {
    final off = _formatOffset(tzOffsetMinutes);
    if (tzOffsetMinutes == deviceTzOffset && deviceTzName.isNotEmpty) {
      return '$deviceTzName ($off)';
    }
    return off;
  }

  Future<void> _pickTimeZone() async {
    // Список смещений от UTC-12 до UTC+14 (плюс системное, если оно дробное)
    final offsets = <int>{
      for (int h = -12; h <= 14; h++) h * 60,
      deviceTzOffset,
    }.toList()
      ..sort();

    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text('Часовой пояс',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              for (final o in offsets)
                ListTile(
                  leading: Icon(
                    o == tzOffsetMinutes
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(
                    o == deviceTzOffset
                        ? '${_formatOffset(o)} · $deviceTzName (системный)'
                        : _formatOffset(o),
                  ),
                  onTap: () => Navigator.pop(ctx, o),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null) setState(() => tzOffsetMinutes = chosen);
  }

  String _baseName(String p) => p.split(RegExp(r'[\\/]+')).last;

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
    );

    if (result != null) {
      setState(() {
        locationController.text = result.address ?? result.name;
        locationLatitude = result.latitude;
        locationLongitude = result.longitude;
      });
    }
  }

  Future<void> _addManualContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить контакт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Телефон (необязательно)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final phone = phoneController.text.trim();
                Navigator.pop(ctx, {
                  'name': name,
                  'phone': phone,
                });
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null) {
      final name = result['name']!;
      final phone = result['phone']!;
      final contactEntry = phone.isNotEmpty ? '$name | $phone' : name;
      setState(() {
        if (!contacts.contains(contactEntry)) {
          contacts.add(contactEntry);
        }
      });
    }
  }

  Future<void> _pickContact() async {
    try {
      final picked = await FlutterContacts.openExternalPick();
      if (picked == null) return;

      // Пытаемся достать номер телефона из выбранного контакта
      String phone =
          picked.phones.isNotEmpty ? picked.phones.first.number : '';
      if (phone.isEmpty && picked.id.isNotEmpty) {
        try {
          if (await FlutterContacts.requestPermission(readonly: true)) {
            final full = await FlutterContacts.getContact(picked.id,
                withProperties: true);
            if (full != null && full.phones.isNotEmpty) {
              phone = full.phones.first.number;
            }
          }
        } catch (_) {}
      }

      final name = picked.displayName.isNotEmpty
          ? picked.displayName
          : (phone.isNotEmpty ? phone : 'Контакт');
      final contactEntry = phone.isNotEmpty ? '$name | $phone' : name;
      setState(() {
        if (!contacts.contains(contactEntry)) {
          contacts.add(contactEntry);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось выбрать контакт: $e')),
        );
      }
    }
  }

  // Открывает системный набор номера с уже введённым номером.
  Future<void> _dial(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^\d+*#]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть набор номера')),
      );
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        setState(() {
          for (final f in result.files) {
            final path = f.path ?? f.name;
            if (!attachments.contains(path)) attachments.add(path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось прикрепить файл: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();
    final glass = isGlassTheme(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final isEvent = activeTabIndex == 0;
    final isTask = activeTabIndex == 1;
    final isBirthday = activeTabIndex == 2;

    // ===== Цвета по теме =====
    final Color scaffoldBgColor;
    final Color pillBackgroundColor;
    final Color dropdownMenuBackgroundColor;
    final Color textColor;
    final Color iconColor;

    if (glass) {
      scaffoldBgColor = Colors.transparent;
      textColor = isLight ? Colors.black : Colors.white;
      iconColor = isLight
          ? Colors.black.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.7);
      pillBackgroundColor =
          Colors.white.withValues(alpha: isLight ? 0.45 : 0.12);
      dropdownMenuBackgroundColor =
          isLight ? const Color(0xFFF4F4F8) : const Color(0xFF20202C);
    } else {
      scaffoldBgColor = theme.scaffoldBackgroundColor;
      pillBackgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
      dropdownMenuBackgroundColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface;
      iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    }

    final customTextStyle = TextStyle(color: textColor, fontSize: 16);

    Widget glassPill(Widget child) {
      const pad = EdgeInsets.symmetric(horizontal: 16);
      if (!glass) {
        return Container(
          decoration: ShapeDecoration(
            color: pillBackgroundColor,
            shape: const StadiumBorder(),
          ),
          padding: pad,
          child: child,
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isLight ? 0.5 : 0.14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: isLight ? 0.75 : 0.22),
                width: 0.8,
              ),
            ),
            padding: pad,
            child: child,
          ),
        ),
      );
    }

    Widget removableChip(String label, VoidCallback onRemove) {
      return Chip(
        label: Text(label,
            style: TextStyle(color: textColor, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        backgroundColor: pillBackgroundColor,
        deleteIconColor: iconColor,
        onDeleted: onRemove,
        side: glass
            ? BorderSide(
                color: Colors.white.withValues(alpha: isLight ? 0.6 : 0.2),
                width: 0.8)
            : BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    // Чип контакта: имя + кнопка позвонить (если есть номер) + удалить
    Widget contactChip(String name) {
      final phone = contactPhones[name];
      return Container(
        decoration: ShapeDecoration(
          color: pillBackgroundColor,
          shape: StadiumBorder(
            side: glass
                ? BorderSide(
                    color: Colors.white.withValues(alpha: isLight ? 0.6 : 0.2),
                    width: 0.8)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(name,
                  style: TextStyle(color: textColor, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            if (phone != null && phone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.call, size: 18),
                color: theme.colorScheme.primary,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                tooltip: 'Позвонить',
                onPressed: () => _dial(phone),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: iconColor,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              onPressed: () => setState(() {
                contacts.remove(name);
                contactPhones.remove(name);
              }),
            ),
          ],
        ),
      );
    }

    // ── Переиспользуемые строки ──────────────────────────────────
    Widget repeatPill() => Row(
          children: [
            Icon(Icons.refresh, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: glassPill(
                DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<RepeatType>(
                    key: ValueKey('repeat_$repeatType'),
                    initialValue: repeatType,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(20),
                    dropdownColor: dropdownMenuBackgroundColor,
                    iconEnabledColor: textColor,
                    style: customTextStyle,
                    onTap: () => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    items: RepeatType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          switch (type) {
                            RepeatType.none => 'Не повторять',
                            RepeatType.daily => 'Каждый день',
                            RepeatType.weekly => 'Каждую неделю',
                            RepeatType.monthly => 'Каждый месяц',
                            RepeatType.yearly => 'Каждый год',
                          },
                          style: customTextStyle,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => repeatType = value);
                    },
                  ),
                ),
              ),
            ),
          ],
        );

    Widget reminderPill() => Row(
          children: [
            Icon(Icons.notifications_none, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: glassPill(
                DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<ReminderOffset>(
                    key: ValueKey('reminder_$reminder'),
                    initialValue: reminder,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(20),
                    dropdownColor: dropdownMenuBackgroundColor,
                    iconEnabledColor: textColor,
                    style: customTextStyle,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    items: ReminderOffset.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r.label, style: customTextStyle),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => reminder = value);
                    },
                  ),
                ),
              ),
            ),
          ],
        );

    Widget descriptionField(String hint) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(Icons.notes, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: descriptionController,
                minLines: 1,
                maxLines: 5,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: iconColor, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

    Widget attachSection() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickFiles,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Прикрепить файл',
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ),
                  ),
                ),
              ],
            ),
            if (attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4, bottom: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: attachments
                      .map((p) => removableChip(_baseName(p),
                          () => setState(() => attachments.remove(p))))
                      .toList(),
                ),
              ),
          ],
        );

    Widget startDateTimeRow({required bool showTime}) => Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      startDate = picked;
                      if (endDate.isBefore(picked)) endDate = picked;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(_formatDate(startDate),
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ],
                  ),
                ),
              ),
            ),
            if (showTime)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: startTime);
                  if (picked != null) setState(() => startTime = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(startTime.format(context),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ],
                  ),
                ),
              ),
          ],
        );

    Widget endDateTimeRow() => Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                    firstDate: startDate,
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => endDate = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Text(_formatDate(endDate),
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ],
                  ),
                ),
              ),
            ),
            if (!isAllDay)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: endTime);
                  if (picked != null) setState(() => endTime = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Text(endTime.format(context),
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ],
                  ),
                ),
              ),
          ],
        );

    Widget allDayToggle() => Row(
          children: [
            Icon(Icons.access_time_filled, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Весь день',
                  style: TextStyle(fontSize: 16, color: textColor)),
            ),
            CupertinoSwitch(
              value: isAllDay,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (value) => setState(() => isAllDay = value),
            ),
          ],
        );

    Widget simpleTapRow({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) =>
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(label,
                      style: TextStyle(fontSize: 16, color: textColor)),
                ),
              ),
            ),
          ],
        );

    Widget birthdayDateRow() => Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      startDate = picked;
                      endDate = picked;
                    });
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.cake_outlined,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(_formatDayMonth(startDate),
                          style: TextStyle(fontSize: 16, color: textColor)),
                      const SizedBox(width: 10),
                      Text('повторяется ежегодно',
                          style: TextStyle(fontSize: 13, color: iconColor)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

    // Напоминания для дня рождения — вспомогательные методы
    Future<int?> pickDaysBefore() async {
      final controller = TextEditingController(text: '3');
      return showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('За сколько дней?'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Количество дней'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text);
                if (v != null && v >= 0) Navigator.pop(ctx, v);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    Widget quickReminderChip(String label, int daysBefore) {
      return ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () async {
          int days = daysBefore;
          if (daysBefore == -1) {
            final picked = await pickDaysBefore();
            if (picked == null) return;
            days = picked;
          }
          if (!context.mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 9, minute: 0),
          );
          if (time == null) return;
          setState(() => birthdayReminders.add(_BirthdayReminder(
            daysBefore: days,
            time: time,
          )));
        },
      );
    }

    Widget birthdayRemindersSection(Color textColor, Color iconColor) {
      String reminderLabel(_BirthdayReminder r) {
        if (r.daysBefore == 0) return 'В день рождения';
        if (r.daysBefore == 1) return 'За 1 день';
        return 'За ${r.daysBefore} дней';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_none, color: iconColor),
              const SizedBox(width: 16),
              Text('Напоминания', style: TextStyle(fontSize: 16, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          ...birthdayReminders.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final timeStr = r.time.format(context);
            return Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.alarm, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${reminderLabel(r)} в $timeStr',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: r.time,
                      );
                      if (picked != null && mounted) {
                        setState(() => birthdayReminders[i] = _BirthdayReminder(
                          daysBefore: r.daysBefore,
                          time: picked,
                        ));
                      }
                    },
                    child: Text(timeStr,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => birthdayReminders.removeAt(i)),
                    child: Icon(Icons.close, size: 18, color: iconColor),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                quickReminderChip('В день', 0),
                quickReminderChip('За 1 день', 1),
                quickReminderChip('За 2 дня', 2),
                quickReminderChip('Другое...', -1),
              ],
            ),
          ),
        ],
      );
    }

    // Выбор категории с цветным кружком (для «Задачи»).
    // Кружок = тот же цвет, которым событие рисуется в месяце/дне.
    Widget taskCategoryRow() {
      const cats = [
        EventCategory.work,
        EventCategory.sport,
        EventCategory.study,
        EventCategory.personal,
        EventCategory.important,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_outline, color: iconColor),
              const SizedBox(width: 16),
              Text('Категория',
                  style: TextStyle(fontSize: 16, color: textColor)),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((c) {
                final cColor = c.color;
                final selected = category == c;
                return GestureDetector(
                  onTap: () => setState(() {
                    category = c;
                    selectedColor = cColor.toARGB32();
                  }),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: ShapeDecoration(
                      color: selected
                          ? cColor.withValues(alpha: 0.18)
                          : pillBackgroundColor,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: selected
                              ? cColor
                              : (glass
                                  ? Colors.white
                                      .withValues(alpha: isLight ? 0.6 : 0.2)
                                  : Colors.transparent),
                          width: selected ? 1.6 : 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: cColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.label,
                            style: TextStyle(fontSize: 14, color: textColor)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // ── Сборка полей под активную вкладку ─────────────────────────
    final List<Widget> fields = [];

    if (isBirthday) {
      // День рождения: дата, напоминания (список)
      fields.addAll([
        birthdayDateRow(),
        const Divider(height: 30),
        birthdayRemindersSection(textColor, iconColor),
      ]);
    } else if (isTask) {
      // Задача: весь день, дата(+время), повтор, срок, описание, файл
      fields.addAll([
        allDayToggle(),
        const SizedBox(height: 10),
        startDateTimeRow(showTime: !isAllDay),
        const Divider(height: 30),
        repeatPill(),
        const SizedBox(height: 8),
        simpleTapRow(
          icon: Icons.track_changes,
          label: dueDate == null ? 'Добавить срок' : 'Срок: ${_formatDate(dueDate!)}',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate ?? startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) setState(() => dueDate = picked);
          },
        ),
        const Divider(height: 30),
        descriptionField('Добавить дополнительную информацию'),
        const SizedBox(height: 12),
        attachSection(),
      ]);
    } else if (isEvent) {
      // Мероприятие: полный набор + категории
      fields.addAll([
        allDayToggle(),
        const SizedBox(height: 10),
        startDateTimeRow(showTime: !isAllDay),
        endDateTimeRow(),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.public, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickTimeZone,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Часовой пояс: ${_tzLabel()}',
                      style: TextStyle(fontSize: 16, color: textColor)),
                ),
              ),
            ),
            Icon(Icons.expand_more, color: iconColor),
          ],
        ),
        const Divider(height: 30),
        taskCategoryRow(),
        const SizedBox(height: 16),
        repeatPill(),
        const SizedBox(height: 16),
        simpleTapRow(
            icon: Icons.person_add_alt,
            label: 'Добавить контакт из книги',
            onTap: _pickContact),
        simpleTapRow(
            icon: Icons.person_add,
            label: 'Добавить контакт вручную',
            onTap: _addManualContact),
        if (contacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4, bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contacts.map((c) => contactChip(c)).toList(),
            ),
          ),
        const SizedBox(height: 8),
        reminderPill(),
        const Divider(height: 36),
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: locationController,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Указать место',
                  hintStyle: TextStyle(color: iconColor, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickLocation,
              icon: Icon(Icons.search, size: 18, color: theme.colorScheme.primary),
              label: Text('Найти', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        descriptionField('Добавьте описание'),
        const SizedBox(height: 12),
        attachSection(),
      ]);
    }

    Widget screenContent = Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing
              ? 'Редактировать'
              : switch (activeTabIndex) {
                  0 => 'Новое мероприятие',
                  1 => 'Новая задача',
                  2 => 'День рождения',
                  _ => 'Новое мероприятие',
                },
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  elevation: glass ? 0 : 2,
                ),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  final navigator = Navigator.of(context);

                  final allDay = isBirthday ? true : isAllDay;
                  final finalStartTime =
                      allDay ? const TimeOfDay(hour: 0, minute: 0) : startTime;
                  final finalEndTime =
                      allDay ? const TimeOfDay(hour: 23, minute: 59) : endTime;

                  // Конечная дата зависит от вкладки
                  final DateTime effectiveEndDate = isBirthday
                      ? startDate
                      : isTask
                          ? (dueDate ?? startDate)
                          : endDate;

                  final startDateTime = DateTime(startDate.year, startDate.month,
                      startDate.day, finalStartTime.hour, finalStartTime.minute);
                  final endDateTime = DateTime(
                      effectiveEndDate.year,
                      effectiveEndDate.month,
                      effectiveEndDate.day,
                      finalEndTime.hour,
                      finalEndTime.minute);

                  if (endDateTime.isBefore(startDateTime) ||
                      endDateTime.isAtSameMomentAs(startDateTime)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Время окончания должно быть позже начала')),
                      );
                    }
                    return;
                  }

                  EventCategory finalCategory = category;
                  if (isTask) finalCategory = EventCategory.task;
                  if (isBirthday) finalCategory = EventCategory.birthday;

                  final finalRepeat = isBirthday ? RepeatType.yearly : repeatType;

                  final loc = locationController.text.trim();
                  final desc = descriptionController.text.trim();

                  // Кодируем напоминания дня рождения
                  String? birthdayRemindersStr;
                  if (isBirthday && birthdayReminders.isNotEmpty) {
                    birthdayRemindersStr = birthdayReminders
                        .map((r) => '${r.daysBefore}:${r.time.hour}:${r.time.minute}')
                        .join('|');
                  }

                  if (_isEditing) {
                    final e = widget.editEvent!;
                    e.title = titleController.text.trim();
                    e.start = startDateTime;
                    e.end = endDateTime;
                    e.repeatType = finalRepeat;
                    e.category = finalCategory;
                    e.reminderMinutes = reminder.minutes;
                    e.color = selectedColor;
                    e.location = loc.isEmpty ? null : loc;
                    e.locationLatitude = locationLatitude;
                    e.locationLongitude = locationLongitude;
                    e.description = desc.isEmpty ? null : desc;
                    e.contacts = contacts.isEmpty ? null : List.of(contacts);
                    e.attachments = attachments.isEmpty ? null : List.of(attachments);
                    e.timeZoneOffset =
                        (isEvent && tzOffsetMinutes != deviceTzOffset)
                            ? tzOffsetMinutes
                            : null;
                    e.birthdayReminders = birthdayRemindersStr;
                    e.dueDate = dueDate;
                    await provider.updateEvent(e);
                  } else {
                    await provider.addEvent(
                      title: titleController.text.trim(),
                      start: startDateTime,
                      end: endDateTime,
                      repeatType: finalRepeat,
                      category: finalCategory,
                      reminder: reminder,
                      color: selectedColor,
                      location: loc.isEmpty ? null : loc,
                      locationLatitude: locationLatitude,
                      locationLongitude: locationLongitude,
                      description: desc.isEmpty ? null : desc,
                      contacts: contacts.isEmpty ? null : List.of(contacts),
                      attachments: attachments.isEmpty ? null : List.of(attachments),
                      timeZoneOffset:
                          (isEvent && tzOffsetMinutes != deviceTzOffset)
                              ? tzOffsetMinutes
                              : null,
                      birthdayReminders: birthdayRemindersStr,
                      dueDate: dueDate,
                    );
                  }

                  navigator.pop();
                },
                child: const Text('Сохранить',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ВЕРХНИЕ ТАБЫ
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topTabs.length,
                itemBuilder: (context, index) {
                  final isSelected = activeTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(
                        topTabs[index],
                        style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : textColor),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: pillBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: glass && !isSelected
                            ? BorderSide(
                                color: Colors.white.withValues(
                                    alpha: isLight ? 0.7 : 0.22),
                                width: 0.8,
                              )
                            : BorderSide.none,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => activeTabIndex = index);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // ВВОД НАЗВАНИЯ
            TextField(
              controller: titleController,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w500, color: textColor),
              decoration: InputDecoration(
                hintText: switch (activeTabIndex) {
                  0 => 'Название мероприятия',
                  1 => 'Добавьте название задачи',
                  2 => 'Имя именинника',
                  _ => 'Название мероприятия',
                },
                border: InputBorder.none,
                hintStyle: TextStyle(color: iconColor),
              ),
            ),
            const Divider(height: 20),

            ...fields,

            const SizedBox(height: 30),
          ],
        ),
      ),
    );

    if (!glass) return screenContent;

    return GlassBackdrop(child: screenContent);
  }
}

/// Модель напоминания для дня рождения.
class _BirthdayReminder {
  final int daysBefore; // 0 = в день события, 1 = за день, и т.д.
  final TimeOfDay time;

  const _BirthdayReminder({required this.daysBefore, required this.time});
}
