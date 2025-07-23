// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'led_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LEDModelAdapter extends TypeAdapter<LEDModel> {
  @override
  final int typeId = 0;

  @override
  LEDModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LEDModel(
      name: fields[0] as String,
      manufacturer: fields[1] as String,
      model: fields[2] as String,
      pitch: fields[3] as double,
      fullHeight: fields[4] as double,
      halfHeight: fields[5] as double,
      width: fields[6] as double,
      depth: fields[7] as double,
      fullPanelWeight: fields[8] as double,
      halfPanelWeight: fields[9] as double,
      hPixel: fields[10] as int,
      wPixel: fields[11] as int,
      halfHPixel: fields[31] as int,
      halfWPixel: fields[32] as int,
      halfWidth: fields[33] as double,
      fullPanelMaxW: fields[12] as double,
      halfPanelMaxW: fields[13] as double,
      fullPanelAvgW: fields[14] as double,
      halfPanelAvgW: fields[15] as double,
      processing: fields[16] as String,
      brightness: fields[17] as int,
      viewingAngle: fields[18] as String,
      refreshRate: fields[19] as int,
      ledConfiguration: fields[20] as String,
      ipRating: fields[21] as String,
      curveCapability: fields[22] as String,
      verification: fields[23] as String,
      dataConnection: fields[24] as String,
      powerConnection: fields[25] as String,
      touringFrame: fields[26] as String,
      supplier: fields[27] as String,
      operatingVoltage: fields[28] as String,
      operatingTemp: fields[29] as String,
      dateAdded: fields[30] as DateTime,
      panelsPerPort: fields[34] as int,
      panelsPer16A: fields[35] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LEDModel obj) {
    writer
      ..writeByte(36)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.manufacturer)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.pitch)
      ..writeByte(4)
      ..write(obj.fullHeight)
      ..writeByte(5)
      ..write(obj.halfHeight)
      ..writeByte(6)
      ..write(obj.width)
      ..writeByte(7)
      ..write(obj.depth)
      ..writeByte(8)
      ..write(obj.fullPanelWeight)
      ..writeByte(9)
      ..write(obj.halfPanelWeight)
      ..writeByte(10)
      ..write(obj.hPixel)
      ..writeByte(11)
      ..write(obj.wPixel)
      ..writeByte(31)
      ..write(obj.halfHPixel)
      ..writeByte(32)
      ..write(obj.halfWPixel)
      ..writeByte(33)
      ..write(obj.halfWidth)
      ..writeByte(12)
      ..write(obj.fullPanelMaxW)
      ..writeByte(13)
      ..write(obj.halfPanelMaxW)
      ..writeByte(14)
      ..write(obj.fullPanelAvgW)
      ..writeByte(15)
      ..write(obj.halfPanelAvgW)
      ..writeByte(16)
      ..write(obj.processing)
      ..writeByte(17)
      ..write(obj.brightness)
      ..writeByte(18)
      ..write(obj.viewingAngle)
      ..writeByte(19)
      ..write(obj.refreshRate)
      ..writeByte(20)
      ..write(obj.ledConfiguration)
      ..writeByte(21)
      ..write(obj.ipRating)
      ..writeByte(22)
      ..write(obj.curveCapability)
      ..writeByte(23)
      ..write(obj.verification)
      ..writeByte(24)
      ..write(obj.dataConnection)
      ..writeByte(25)
      ..write(obj.powerConnection)
      ..writeByte(26)
      ..write(obj.touringFrame)
      ..writeByte(27)
      ..write(obj.supplier)
      ..writeByte(28)
      ..write(obj.operatingVoltage)
      ..writeByte(29)
      ..write(obj.operatingTemp)
      ..writeByte(30)
      ..write(obj.dateAdded)
      ..writeByte(34)
      ..write(obj.panelsPerPort)
      ..writeByte(35)
      ..write(obj.panelsPer16A);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LEDModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
