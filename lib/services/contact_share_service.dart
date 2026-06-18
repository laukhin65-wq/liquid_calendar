import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/calendar_event.dart';
import '../data/models/contact_model.dart';
import '../data/models/event_category.dart';
import 'vcard_generator.dart';

class ContactShareService {
  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _buildContactText(ContactModel contact) {
    final buf = StringBuffer('\n👤 Контакт:\n${contact.name}');
    if (contact.phone != null && contact.phone!.isNotEmpty) {
      buf.write('\n📱 ${contact.phone}');
    }
    if (contact.email != null && contact.email!.isNotEmpty) {
      buf.write('\n📧 ${contact.email}');
    }
    if (contact.company != null && contact.company!.isNotEmpty) {
      buf.write('\n🏢 ${contact.company}');
    }
    return buf.toString();
  }

  static String buildFullText(CalendarEvent event, ContactModel? contact) {
    final cat = event.category;
    final buf = StringBuffer();
    buf.writeln(event.title);
    buf.writeln('');
    buf.writeln('📅 Дата: ${_formatDate(event.start)}');
    buf.writeln('🕐 Время: ${_formatTime(event.start)} – ${_formatTime(event.end)}');
    buf.writeln('🏷 Категория: ${cat.label}');
    if (event.location != null && event.location!.isNotEmpty) {
      buf.writeln('📍 Место: ${event.location}');
      if (event.locationLatitude != null && event.locationLongitude != null) {
        buf.writeln('📌 Координаты: ${event.locationLatitude}, ${event.locationLongitude}');
        buf.writeln('🗺 Открыть на карте: https://maps.google.com/?q=${event.locationLatitude},${event.locationLongitude}');
      } else {
        buf.writeln('🗺 Открыть на карте: https://maps.google.com/?q=${Uri.encodeComponent(event.location!)}');
      }
    }
    if (event.description != null && event.description!.isNotEmpty) {
      buf.writeln('');
      buf.writeln(event.description);
    }
    if (contact != null) {
      buf.writeln(_buildContactText(contact));
    }
    return buf.toString();
  }

  static String _determineMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  static Future<void> shareEventWithContact(
      CalendarEvent event, ContactModel? contact, BuildContext context) async {
    final text = buildFullText(event, contact);
    final files = <XFile>[];

    if (contact != null) {
      try {
        final vCardFile = await VCardGenerator.generate(contact);
        files.add(XFile(vCardFile.path, mimeType: 'text/x-vcard'));
      } catch (_) {}
    }

    if (event.attachments != null) {
      for (final path in event.attachments!) {
        final file = File(path);
        if (await file.exists()) {
          files.add(XFile(path, mimeType: _determineMimeType(path)));
        }
      }
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Текст скопирован. Нажмите «Вставить» в поле сообщения.'),
          duration: Duration(seconds: 3),
          backgroundColor: Color(0xFF2C2C2E),
        ),
      );
    }

    if (files.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: files, text: text));
    } else {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  static Future<void> shareContactAsVCard(ContactModel contact) async {
    try {
      final file = await VCardGenerator.generate(contact);
      final xfile = XFile(file.path, mimeType: 'text/x-vcard');
      await SharePlus.instance.share(ShareParams(files: [xfile]));
    } catch (e) {
      final text = _buildContactText(contact);
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }
}
