import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/models/contact_model.dart';

class VCardGenerator {
  static Future<File> generate(ContactModel contact) async {
    final buf = StringBuffer();
    buf.write('BEGIN:VCARD\r\n');
    buf.write('VERSION:3.0\r\n');
    buf.write('FN:${contact.name}\r\n');
    buf.write('N:${_escapeVCard(contact.name)};;;\r\n');

    if (contact.phone != null && contact.phone!.isNotEmpty) {
      buf.write('TEL;TYPE=CELL:${contact.phone}\r\n');
    }
    if (contact.email != null && contact.email!.isNotEmpty) {
      buf.write('EMAIL:${contact.email}\r\n');
    }
    if (contact.company != null && contact.company!.isNotEmpty) {
      buf.write('ORG:${_escapeVCard(contact.company!)}\r\n');
    }
    buf.write('REV:${DateTime.now().toUtc().toIso8601String()}\r\n');
    buf.write('END:VCARD\r\n');

    final dir = await getTemporaryDirectory();
    final safeName = contact.name.replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9]'), '_');
    final file = File('${dir.path}/contact_$safeName.vcf');
    await file.writeAsString(buf.toString(), encoding: utf8);
    return file;
  }

  static String _escapeVCard(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }
}
