import 'package:hive/hive.dart';
import 'activity_plan.dart';

class ActivityPlanAdapter extends TypeAdapter<ActivityPlan> {
  @override
  final int typeId = 20; // <-- SENDEKİ ESKİ typeId NEYSE ONU YAZ

  @override
  ActivityPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ActivityPlan(
      id: fields[0] as String,
      title: (fields[1] as String),
      minutes: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityPlan obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.minutes);
  }
}
