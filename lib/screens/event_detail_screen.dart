import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:map_launcher/map_launcher.dart';
import '../data/models/repeat_type.dart';
import '../data/models/event_category.dart';
import '../data/models/reminder_offset.dart';
import '../providers/calendar_provider.dart';
import '../services/export_service.dart';
import '../widgets/glass.dart';
import 'add_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final event = provider.getEventById(eventId);
    if (event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: const Center(child: Text('Событие удалено', style: TextStyle(color: Colors.white))),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glass = isGlassTheme(context);
    final cat = event.category;
    final isTask = cat == EventCategory.task;
    final isMeeting = event.isMeeting;

    final eventColor = event.color != 0
        ? Color(event.color)
        : cat.color;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final bgColor = glass ? Colors.transparent : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

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

    final isHoliday = cat == EventCategory.holiday;

    Widget screenContent = Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: !isHoliday
          ? FloatingActionButton(
              onPressed: () => showCustomShareSheet(context, event),
              backgroundColor: scheme.primary,
              child: Icon(Icons.share, color: scheme.onPrimary),
            )
          : null,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isHoliday) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEventScreen(editEvent: event),
                  ),
                );
              },
              icon: Icon(Icons.edit_outlined, size: 18, color: scheme.primary),
              label: Text('Редактировать', style: TextStyle(color: scheme.primary)),
            ),
            TextButton.icon(
              onPressed: () {
                context.read<CalendarProvider>().deleteEvent(event.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${event.title}" удалено')),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              label: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
        children: [
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

          if (isHoliday)
            detailRow(Icons.calendar_today, 'Дата',
                '${event.start.day.toString().padLeft(2, '0')}.${event.start.month.toString().padLeft(2, '0')}.${event.start.year}')
          else ...[
            detailRow(Icons.schedule, 'Начало', formatDateTime(event.start)),
            detailRow(Icons.flag, 'Окончание', formatDateTime(event.end)),
          ],

          if (event.repeatType != RepeatType.none && !isHoliday)
            detailRow(Icons.refresh, 'Повторение',
                event.repeatType.label),

          if (!isHoliday)
            detailRow(
              Icons.notifications_none,
              'Напоминание',
              event.reminderMinutes == null
                  ? 'Нет'
                  : ReminderOffsetX.fromMinutes(event.reminderMinutes).label,
            ),

          if (event.location != null && event.location!.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final availableMaps = await MapLauncher.installedMaps;
                if (availableMaps.isNotEmpty) {
                  await availableMaps.first.showMarker(
                    coords: Coords(
                      event.locationLatitude ?? 0,
                      event.locationLongitude ?? 0,
                    ),
                    title: event.location!,
                    description: event.description ?? '',
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 20, color: eventColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Место',
                              style: TextStyle(fontSize: 12, color: subtextColor)),
                          const SizedBox(height: 2),
                          Text(event.location!,
                              style: TextStyle(fontSize: 15, color: eventColor)),
                          if (event.locationLatitude != null)
                            Text(
                              '${event.locationLatitude!.toStringAsFixed(4)}, ${event.locationLongitude!.toStringAsFixed(4)}',
                              style: TextStyle(fontSize: 12, color: subtextColor),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: subtextColor),
                  ],
                ),
              ),
            ),

          if (event.description != null && event.description!.isNotEmpty)
            detailRow(Icons.notes, 'Описание', event.description!),

          if (event.contacts != null && event.contacts!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person_outline, size: 20, color: eventColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Контакт',
                            style: TextStyle(fontSize: 12, color: subtextColor)),
                        const SizedBox(height: 4),
                        for (final raw in event.contacts!) ...[
                          Builder(
                            builder: (context) {
                              final parts = raw.split(' | ');
                              final contactName = parts[0];
                              final phone = parts.length > 1 ? parts[1] : null;
                              return GestureDetector(
                                onTap: phone != null ? () async {
                                  final uri = Uri(scheme: 'tel', path: phone);
                                  if (await canLaunchUrl(uri)) launchUrl(uri);
                                } : null,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    phone != null ? '$contactName\n$phone' : contactName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: eventColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (event.attachments != null && event.attachments!.isNotEmpty)
            detailRow(
              Icons.attach_file,
              'Файлы',
              event.attachments!.map((p) => p.split(RegExp(r'[\\/]+')).last).join(', '),
            ),

          if (isMeeting && event.contacts != null && event.contacts!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final raw = event.contacts!.first;
                  final parts = raw.split(' | ');
                  final phone = parts.length > 1 ? parts[1] : null;
                  if (phone != null && phone.isNotEmpty) {
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.call, size: 20),
                label: const Text('Позвонить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],

          if (isMeeting && event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final availableMaps = await MapLauncher.installedMaps;
                  if (availableMaps.isNotEmpty) {
                    await availableMaps.first.showMarker(
                      coords: Coords(
                        event.locationLatitude ?? 0,
                        event.locationLongitude ?? 0,
                      ),
                      title: event.location!,
                      description: event.description ?? '',
                    );
                  }
                },
                icon: const Icon(Icons.directions, size: 20),
                label: const Text('Построить маршрут'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (isTask)
            SizedBox(
              width: double.infinity,
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
        ],
      ),
    );

    if (!glass) return screenContent;
    return GlassBackdrop(child: screenContent);
  }
}
