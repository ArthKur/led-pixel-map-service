import 'package:hive/hive.dart';

part 'led_model.g.dart';

@HiveType(typeId: 0)
class LEDModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String manufacturer;

  @HiveField(2)
  String model;

  @HiveField(3)
  double pitch;

  @HiveField(4)
  double fullHeight;

  @HiveField(5)
  double halfHeight;

  @HiveField(6)
  double width;

  @HiveField(7)
  double depth;

  @HiveField(8)
  double fullPanelWeight;

  @HiveField(9)
  double halfPanelWeight;

  @HiveField(10)
  int hPixel;

  @HiveField(11)
  int wPixel;

  @HiveField(31)
  int halfHPixel;

  @HiveField(32)
  int halfWPixel;

  @HiveField(33)
  double halfWidth;

  @HiveField(12)
  double fullPanelMaxW;

  @HiveField(13)
  double halfPanelMaxW;

  @HiveField(14)
  double fullPanelAvgW;

  @HiveField(15)
  double halfPanelAvgW;

  @HiveField(16)
  String processing;

  @HiveField(17)
  int brightness;

  @HiveField(18)
  String viewingAngle;

  @HiveField(19)
  int refreshRate;

  @HiveField(20)
  String ledConfiguration;

  @HiveField(21)
  String ipRating;

  @HiveField(22)
  String curveCapability;

  @HiveField(23)
  String verification;

  @HiveField(24)
  String dataConnection;

  @HiveField(25)
  String powerConnection;

  @HiveField(26)
  String touringFrame;

  @HiveField(27)
  String supplier;

  @HiveField(28)
  String operatingVoltage;

  @HiveField(29)
  String operatingTemp;

  @HiveField(30)
  DateTime dateAdded;

  @HiveField(34)
  int panelsPerPort;

  @HiveField(35)
  int panelsPer16A;

  @HiveField(36)
  double caseVolume;

  @HiveField(37)
  int panelsPerCase;

  LEDModel({
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.pitch,
    required this.fullHeight,
    required this.halfHeight,
    required this.width,
    required this.depth,
    required this.fullPanelWeight,
    required this.halfPanelWeight,
    required this.hPixel,
    required this.wPixel,
    required this.halfHPixel,
    required this.halfWPixel,
    required this.halfWidth,
    required this.fullPanelMaxW,
    required this.halfPanelMaxW,
    required this.fullPanelAvgW,
    required this.halfPanelAvgW,
    required this.processing,
    required this.brightness,
    required this.viewingAngle,
    required this.refreshRate,
    required this.ledConfiguration,
    required this.ipRating,
    required this.curveCapability,
    required this.verification,
    required this.dataConnection,
    required this.powerConnection,
    required this.touringFrame,
    required this.supplier,
    required this.operatingVoltage,
    required this.operatingTemp,
    required this.dateAdded,
    this.panelsPerPort = 0,
    this.panelsPer16A = 0,
    this.caseVolume = 0.0,
    this.panelsPerCase = 0,
  });

  @override
  String toString() {
    return '$manufacturer $name ($model) - ${pitch}mm';
  }
}
