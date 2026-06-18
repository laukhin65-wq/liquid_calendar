// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 0;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      start: fields[2] as DateTime,
      end: fields[3] as DateTime,
      color: fields[4] as int,
      repeatType: RepeatType.values[fields[5] as int],
      category: EventCategory.values[fields[6] as int],
      notificationId: fields[7] as String?,
      reminderMinutes: fields[8] as int?,
      location: fields[9] as String?,
      locationLatitude: fields[17] as double?,
      locationLongitude: fields[18] as double?,
      description: fields[10] as String?,
      contacts: (fields[11] as List?)?.cast<String>(),
      attachments: (fields[12] as List?)?.cast<String>(),
      timeZoneOffset: fields[13] as int?,
      isCompleted: fields[14] as bool,
      birthdayReminders: fields[15] as String?,
      dueDate: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.start)
      ..writeByte(3)
      ..write(obj.end)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.repeatType.index)
      ..writeByte(6)
      ..write(obj.category.index)
      ..writeByte(7)
      ..write(obj.notificationId)
      ..writeByte(8)
      ..write(obj.reminderMinutes)
      ..writeByte(9)
      ..write(obj.location)
      ..writeByte(17)
      ..write(obj.locationLatitude)
      ..writeByte(18)
      ..write(obj.locationLongitude)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.contacts)
      ..writeByte(12)
      ..write(obj.attachments)
      ..writeByte(13)
      ..write(obj.timeZoneOffset)
      ..writeByte(14)
      ..write(obj.isCompleted)
      ..writeByte(15)
      ..write(obj.birthdayReminders)
      ..writeByte(16)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
