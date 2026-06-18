import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/calendar_event.dart';
import '../data/models/repeat_type.dart';
import '../data/models/event_category.dart';
import '../data/models/reminder_offset.dart';
import '../providers/calendar_provider.dart';
import '../screens/add_event_screen.dart';
import 'glass.dart';

/// Панель деталей события (read-only). Открывается снизу как bottom sheet.
/// Кнопка «Редактировать» → переход в [AddEventScreen].
/// Для задач额外 кнопка «Задача выполнена» → зачёркивание.
class EventDetailSheet extends StatelessWidget {
  final CalendarEvent event;
  const EventDetailSheet({super.key, required this.event});

  static void show(BuildContext context, CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = isGlassTheme(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cat = event.category;
    final isTask = cat == EventCategory.task;

    final eventColor = event.color != 0
        ? Color(event.color)
        : cat.color;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    Widget detailRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: eventColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 12, color: subtextColor)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(fontSize: 15, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String formatDateTime(DateTime dt) {
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final content = DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: glass
                ? (isDark
                    ? const Color(0xFF1C1C2E).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92))
                : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: subtextColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: eventColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        decoration: (isTask && event.isCompleted)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(cat.label,
                    style: TextStyle(fontSize: 12, color: eventColor, fontWeight: FontWeight.w500)),
              ),

              Divider(height: 32, color: dividerColor),

              // Date/time
              detailRow(Icons.schedule, 'Начало', formatDateTime(event.start)),
              detailRow(Icons.flag, 'Окончание', formatDateTime(event.end)),

              // Repeat
              if (event.repeatType != RepeatType.none)
                detailRow(Icons.refresh, 'Повторение',
                    event.repeatType.label),

              // Reminder
              detailRow(
                Icons.notifications_none,
                'Напоминание',
                event.reminderMinutes == null
                    ? 'Нет'
                    : ReminderOffsetX.fromMinutes(event.reminderMinutes).label,
              ),

              // Location
              if (event.location != null && event.location!.isNotEmpty)
                detailRow(Icons.location_on_outlined, 'Место', event.location!),

              // Description
              if (event.description != null && event.description!.isNotEmpty)
                detailRow(Icons.notes, 'Описание', event.description!),

              // Contacts
              if (event.contacts != null && event.contacts!.isNotEmpty)
                detailRow(Icons.people_outline, 'Контакты', event.contacts!.join(', ')),

              // Attachments
              if (event.attachments != null && event.attachments!.isNotEmpty)
                detailRow(
                  Icons.attach_file,
                  'Файлы',
                  event.attachments!.map((p) => p.split(RegExp(r'[\\/]+')).last).join(', '),
                ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  if (isTask)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<CalendarProvider>().toggleTaskCompletion(event);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          event.isCompleted ? Icons.replay : Icons.check_circle_outline,
                          size: 20,
                        ),
                        label: Text(event.isCompleted ? 'Вернуть' : 'Выполнена'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: event.isCompleted ? Colors.orange : const Color(0xFF34C759),
                          side: BorderSide(
                            color: event.isCompleted ? Colors.orange : const Color(0xFF34C759),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  if (isTask) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEventScreen(editEvent: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Редактировать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Delete
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<CalendarProvider>().deleteEvent(event.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"${event.title}" удалено')),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Удалить'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!glass) return content;

    return BackdropFilter(
      filter: glassBlurFilter(blur: 18, saturation: 1.5),
      child: content,
    );
  }
}
