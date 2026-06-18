import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';

class ShareSelection {
  bool shareText = true;
  bool shareLocation = false;
  bool shareFiles = true;
  List<String> selectedContacts = [];
}

void showCustomShareSheet(BuildContext context, CalendarEvent event) {
  final selection = ShareSelection();
  final hasContacts = event.contacts != null && event.contacts!.isNotEmpty;
  final hasFiles = event.attachments != null && event.attachments!.isNotEmpty;
  final hasLocation = event.location != null && event.location!.isNotEmpty;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: isDark ? Colors.white38 : Colors.black26, borderRadius: BorderRadius.circular(2)))),
                Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('Что отправить?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor))),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Текст события', style: TextStyle(color: textColor)),
                  value: selection.shareText,
                  onChanged: (val) => setModalState(() => selection.shareText = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                if (hasLocation)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Координаты (ссылка на карту)', style: TextStyle(color: textColor)),
                    value: selection.shareLocation,
                    onChanged: (val) => setModalState(() => selection.shareLocation = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                if (hasFiles)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Файлы и вложения', style: TextStyle(color: textColor)),
                    value: selection.shareFiles,
                    onChanged: (val) => setModalState(() => selection.shareFiles = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                if (hasContacts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.contacts, color: theme.colorScheme.primary),
                    title: Text('Контакты (${selection.selectedContacts.length} выбрано)', style: TextStyle(color: textColor)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withValues(alpha: 0.5)),
                    onTap: () async {
                      final selected = await showContactPicker(context, event.contacts!);
                      setModalState(() => selection.selectedContacts = selected);
                    },
                  ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      executeSystemShare(event, selection, context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<List<String>> showContactPicker(BuildContext context, List<String> contacts) async {
  List<String> selected = [];

  return await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: isDark ? Colors.white38 : Colors.black26, borderRadius: BorderRadius.circular(2))),
              Text('Выберите контакты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (ctx, index) {
                    final contact = contacts[index];
                    final parts = contact.split(' | ');
                    final name = parts[0];
                    final phone = parts.length > 1 ? parts[1] : '';
                    final isSelected = selected.contains(contact);

                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name, style: TextStyle(color: textColor)),
                      subtitle: phone.isNotEmpty ? Text(phone, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)) : null,
                      value: isSelected,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selected.add(contact);
                          } else {
                            selected.remove(contact);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: const Text('Готово'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  ) ?? [];
}

Future<void> executeSystemShare(CalendarEvent event, ShareSelection selection, BuildContext context) async {
  final files = <XFile>[];
  final buf = StringBuffer();
  final isMeeting = event.isMeeting;

  if (selection.shareText) {
    buf.writeln('📅 ${event.title}');
    buf.writeln('');
    buf.writeln('📆 Дата: ${event.start.day.toString().padLeft(2, '0')}.${event.start.month.toString().padLeft(2, '0')}.${event.start.year}');
    buf.writeln('⏰ Время: ${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')} – ${event.end.hour.toString().padLeft(2, '0')}:${event.end.minute.toString().padLeft(2, '0')}');
    buf.writeln('🏷 Категория: ${event.category.label}');
    if (event.description != null && event.description!.isNotEmpty) {
      buf.writeln('');
      buf.writeln(event.description);
    }
    if (isMeeting && event.contacts != null && event.contacts!.isNotEmpty) {
      buf.writeln('');
      for (final raw in event.contacts!) {
        final parts = raw.split(' | ');
        final name = parts[0];
        final phone = parts.length > 1 ? parts[1] : null;
        buf.writeln('👤 Контакт: $name');
        if (phone != null && phone.isNotEmpty) {
          buf.writeln('📞 Телефон: $phone');
        }
      }
    }
  }

  if (selection.shareLocation && hasLocation(event)) {
    if (buf.isNotEmpty) buf.writeln('');
    buf.writeln('📍 Место: ${event.location}');
    if (event.locationLatitude != null && event.locationLongitude != null) {
      buf.writeln('📌 Координаты: ${event.locationLatitude}, ${event.locationLongitude}');
      buf.writeln('🗺 Открыть на карте: https://maps.google.com/?q=${event.locationLatitude},${event.locationLongitude}');
    } else {
      buf.writeln('🗺 Открыть на карте: https://maps.google.com/?q=${Uri.encodeComponent(event.location!)}');
    }
  }

  if (selection.shareFiles && hasFiles(event)) {
    for (final path in event.attachments!) {
      final file = File(path);
      if (await file.exists()) {
        final ext = path.toLowerCase();
        String mime = 'application/octet-stream';
        if (ext.endsWith('.png')) {
          mime = 'image/png';
        } else if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
          mime = 'image/jpeg';
        } else if (ext.endsWith('.pdf')) {
          mime = 'application/pdf';
        }
        files.add(XFile(path, mimeType: mime));
      }
    }
  }

  for (final raw in selection.selectedContacts) {
    final parts = raw.split(' | ');
    final name = parts[0];
    final phone = parts.length > 1 ? parts[1] : '';

    final vcf = StringBuffer();
    vcf.write('BEGIN:VCARD\r\n');
    vcf.write('VERSION:3.0\r\n');
    vcf.write('FN:$name\r\n');
    vcf.write('N:$name;;;\r\n');
    if (phone.isNotEmpty) vcf.write('TEL;TYPE=CELL:$phone\r\n');
    vcf.write('END:VCARD\r\n');

    final dir = await Directory.systemTemp.createTemp();
    final file = File('${dir.path}/${name.replaceAll(' ', '_')}.vcf');
    await file.writeAsString(vcf.toString());
    files.add(XFile(file.path, mimeType: 'text/x-vcard'));
  }

  if (files.isNotEmpty) {
    await SharePlus.instance.share(ShareParams(files: files, text: buf.toString()));
  } else if (buf.isNotEmpty) {
    await SharePlus.instance.share(ShareParams(text: buf.toString()));
  }
}

bool hasLocation(CalendarEvent event) => event.location != null && event.location!.isNotEmpty;
bool hasFiles(CalendarEvent event) => event.attachments != null && event.attachments!.isNotEmpty;
