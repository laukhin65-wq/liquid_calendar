import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/repeat_type.dart';
import '../providers/calendar_provider.dart';
import '../data/models/event_category.dart';
import '../data/models/reminder_offset.dart';
import 'glass.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime? initialDate;

  const AddEventDialog({
    super.key,
    this.initialDate,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final controller = TextEditingController();

  late DateTime startDate;
  late DateTime endDate;

  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
  RepeatType repeatType = RepeatType.none;
  EventCategory category = EventCategory.personal;
  ReminderOffset reminder = ReminderOffset.none;

  @override
  void initState() {
    super.initState();
    final baseDate = widget.initialDate ?? context.read<CalendarProvider>().selectedDate;
    startDate = baseDate;
    endDate = baseDate;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();
    final glass = isGlassTheme(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Настройка адаптивных цветов для подложки пилюли и выпадающего меню
    final Color pillBackgroundColor;
    final Color dropdownMenuBackgroundColor;
    final Color textColor;
    final Color labelColor;

    if (glass) {
      if (isLight) {
        pillBackgroundColor = Colors.white.withValues(alpha: 0.45);
        dropdownMenuBackgroundColor = const Color(0xFFF0F0F3);
        textColor = Colors.black87;
        labelColor = Colors.black54;
      } else {
        pillBackgroundColor = Colors.black.withValues(alpha: 0.4);
        dropdownMenuBackgroundColor = const Color(0xFF1A1A1C);
        textColor = Colors.white;
        labelColor = Colors.white70;
      }
    } else {
      pillBackgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      dropdownMenuBackgroundColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface;
      labelColor = theme.colorScheme.onSurfaceVariant;
    }

    // Центрированный стиль для текста
    final customTextStyle = TextStyle(
      color: textColor,
      fontSize: 16,
    );

    final dialog = AlertDialog(
      backgroundColor: glass ? theme.colorScheme.surface.withValues(alpha: isLight ? 0.65 : 0.78) : null,
      shape: glass
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
          : null,
      title: const Text('Новое событие'),
      content: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Название события'),
            ),
            const SizedBox(height: 20),

            // Выбор даты начала
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Дата начала'),
              subtitle: Text('${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')}.${startDate.year}'),
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
                    if (endDate.isBefore(picked)) {
                      endDate = picked;
                    }
                  });
                }
              },
            ),

            // Выбор времени начала
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Время начала'),
              subtitle: Text(startTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: startTime,
                );
                if (picked != null) {
                  setState(() {
                    startTime = picked;
                  });
                }
              },
            ),

            // Выбор даты окончания
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Дата окончания'),
              subtitle: Text('${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                  firstDate: startDate,
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    endDate = picked;
                  });
                }
              },
            ),

            // Выбор времени окончания
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Время окончания'),
              subtitle: Text(endTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: endTime,
                );
                if (picked != null) {
                  setState(() {
                    endTime = picked;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // === ПОВТОРЕНИЕ (ЦЕНТРИРОВАННАЯ ПИЛЮЛЯ СО СКРУГЛЕННЫМ МЕНЮ) ===
            Container(
              decoration: ShapeDecoration(
                color: pillBackgroundColor,
                shape: const StadiumBorder(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: DropdownButtonFormField<RepeatType>(
                key: ValueKey('repeat_$repeatType'),
                initialValue: repeatType,
                isExpanded: true,
                alignment: Alignment.center, // Выравнивание содержимого по центру
                borderRadius: BorderRadius.circular(20), // Скругление углов выпадающего окна
                dropdownColor: dropdownMenuBackgroundColor,
                iconEnabledColor: textColor,
                style: customTextStyle,
                onTap: () => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Повторение',
                  // Центрируем labelText (подпись сверху) внутри пилюли
                  labelStyle: TextStyle(color: labelColor, fontSize: 14),
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: RepeatType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    alignment: Alignment.center, // Текст внутри открытого меню тоже по центру
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
                  if (value != null) {
                    setState(() {
                      repeatType = value;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 14),

            // === КАТЕГОРИЯ (ЦЕНТРИРОВАННАЯ ПИЛЮЛЯ СО СКРУГЛЕННЫМ МЕНЮ) ===
            Container(
              decoration: ShapeDecoration(
                color: pillBackgroundColor,
                shape: const StadiumBorder(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: DropdownButtonFormField<EventCategory>(
                key: ValueKey('category_$category'),
                initialValue: category,
                isExpanded: true,
                alignment: Alignment.center, // Центрирование
                borderRadius: BorderRadius.circular(20), // Скругление окна
                dropdownColor: dropdownMenuBackgroundColor,
                iconEnabledColor: textColor,
                style: customTextStyle,
                onTap: () => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Категория',
                  labelStyle: TextStyle(color: labelColor, fontSize: 14),
                  floatingLabelAlignment: FloatingLabelAlignment.center, // Центрирование подписи
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: EventCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    alignment: Alignment.center, // Элементы меню по центру
                    child: Text(cat.label, style: customTextStyle),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      category = value;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 14),

            // === НАПОМИНАНИЕ (ЦЕНТРИРОВАННАЯ ПИЛЮЛЯ СО СКРУГЛЕННЫМ МЕНЮ) ===
            Container(
              decoration: ShapeDecoration(
                color: pillBackgroundColor,
                shape: const StadiumBorder(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: DropdownButtonFormField<ReminderOffset>(
                key: ValueKey('reminder_$reminder'),
                initialValue: reminder,
                isExpanded: true,
                alignment: Alignment.center, // Центрирование
                borderRadius: BorderRadius.circular(20), // Скругление окна
                dropdownColor: dropdownMenuBackgroundColor,
                iconEnabledColor: textColor,
                style: customTextStyle,
                onTap: () => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Напоминание',
                  labelStyle: TextStyle(color: labelColor, fontSize: 14),
                  floatingLabelAlignment: FloatingLabelAlignment.center, // Центрирование подписи
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: ReminderOffset.values.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    alignment: Alignment.center, // Элементы меню по центру
                    child: Text(r.label, style: customTextStyle),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      reminder = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;

            final navigator = Navigator.of(context);

            final startDateTime = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              startTime.hour,
              startTime.minute,
            );

            final endDateTime = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
              endTime.hour,
              endTime.minute,
            );

            if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Время окончания должно быть позже начала')),
                );
              }
              return;
            }

            await provider.addEvent(
              title: controller.text.trim(),
              start: startDateTime,
              end: endDateTime,
              repeatType: repeatType,
              category: category,
              reminder: reminder,
            );

            navigator.pop();
          },
          child: const Text('Создать'),
        ),
      ],
    );

    if (!glass) return dialog;
    return BackdropFilter(
      filter: glassBlurFilter(blur: 18, saturation: 1.5),
      child: dialog,
    );
  }
}