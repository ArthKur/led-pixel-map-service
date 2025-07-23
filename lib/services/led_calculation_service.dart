import '../models/led_model.dart';

class LEDCalculationResult {
  // Summary
  final String ledName;
  final double screenSizeMeters;
  final int totalFullPanels;
  final int totalHalfPanels;
  final String pixelSpace;
  final String aspectRatio;
  final double maxPower;
  final double avgPower;
  final double approxWeight;

  // User Input Dimensions
  final double requestedWidth;
  final double requestedHeight;

  // Totals
  final double sqm;
  final double totalWeight;
  final int totalPx;

  // Shipping
  final int dollysPerCase;
  final double shippingWeight;
  final double shippingVolume;

  // Physical
  final int metersWidth;
  final int metersHeight;
  final int panelsWidth;
  final int panelsHeight;
  final int pixelsWidth;
  final int pixelsHeight;

  // Electrical
  final int maxAmps1Phase;
  final int maxAmps3Phase;
  final int avgAmps1Phase;
  final int avgAmps3Phase;
  final double totalKW;
  final double kWPerHour;
  final String distro;

  // Stacked Rigging
  final int trussUpright;
  final int trussBaseplate;
  final int horizontalPipe;
  final int halfCouplers;
  final int bracingArms;

  // Cables & Processing
  final int firstData;
  final int firstPower;
  final int socapex;
  final int novastarMain;
  final int novastarBU;

  // Weights
  final double screenWeight;
  final double cableWeight;
  final double riggingAllowance;
  final double totalCalculatedWeight;

  // Flown Rigging
  final int singleHeader;
  final int gacSpanset4m;
  final int shackle25t;

  LEDCalculationResult({
    required this.ledName,
    required this.screenSizeMeters,
    required this.totalFullPanels,
    required this.totalHalfPanels,
    required this.pixelSpace,
    required this.aspectRatio,
    required this.maxPower,
    required this.avgPower,
    required this.approxWeight,
    required this.requestedWidth,
    required this.requestedHeight,
    required this.sqm,
    required this.totalWeight,
    required this.totalPx,
    required this.dollysPerCase,
    required this.shippingWeight,
    required this.shippingVolume,
    required this.metersWidth,
    required this.metersHeight,
    required this.panelsWidth,
    required this.panelsHeight,
    required this.pixelsWidth,
    required this.pixelsHeight,
    required this.maxAmps1Phase,
    required this.maxAmps3Phase,
    required this.avgAmps1Phase,
    required this.avgAmps3Phase,
    required this.totalKW,
    required this.kWPerHour,
    required this.distro,
    required this.trussUpright,
    required this.trussBaseplate,
    required this.horizontalPipe,
    required this.halfCouplers,
    required this.bracingArms,
    required this.firstData,
    required this.firstPower,
    required this.socapex,
    required this.novastarMain,
    required this.novastarBU,
    required this.screenWeight,
    required this.cableWeight,
    required this.riggingAllowance,
    required this.totalCalculatedWeight,
    required this.singleHeader,
    required this.gacSpanset4m,
    required this.shackle25t,
  });
}

class LEDCalculationService {
  static LEDCalculationResult calculateLEDInstallation(
    LEDModel led,
    double widthMeters,
    double heightMeters,
  ) {
    // Basic calculations
    final double panelWidthMeters = led.width / 1000; // Convert mm to m
    final double panelHeightMeters = led.fullHeight / 1000; // Convert mm to m

    final int panelsWidth = (widthMeters / panelWidthMeters).ceil();
    final int panelsHeight = (heightMeters / panelHeightMeters).ceil();
    final int totalFullPanels = panelsWidth * panelsHeight;
    final int totalHalfPanels = 0; // Simplified for now

    final double actualWidthMeters = panelsWidth * panelWidthMeters;
    final double actualHeightMeters = panelsHeight * panelHeightMeters;
    final double sqm =
        widthMeters * heightMeters; // Based on requested screen size

    final int pixelsWidth = panelsWidth * led.wPixel;
    final int pixelsHeight = panelsHeight * led.hPixel;
    final int totalPx = pixelsWidth * pixelsHeight;

    // Weight calculations
    final double panelWeight = led.fullPanelWeight;
    final double screenWeight =
        (totalFullPanels + totalHalfPanels) *
        panelWeight; // Total panels × panel weight
    final double cableWeight = (screenWeight * 0.1); // 10% rule
    final double riggingAllowance =
        (screenWeight + cableWeight) * 0.2; // 20% rule
    final double totalCalculatedWeight =
        screenWeight + cableWeight + riggingAllowance;

    // Approximate weight calculation: total panels × panel weight + 10%
    final double approxWeightCalc = (totalFullPanels * panelWeight) * 1.1;

    // Power calculations
    final double maxPowerPerPanel = led.fullPanelMaxW;
    final double avgPowerPerPanel = led.fullPanelAvgW;
    final double totalMaxPower = (totalFullPanels * maxPowerPerPanel) / 400;
    final double totalAvgPower = (totalFullPanels * avgPowerPerPanel) / 400;
    final double totalKW = totalMaxPower / 1000;

    // Electrical calculations (assuming 230V)
    final int maxAmps1Phase = (totalMaxPower / 230).ceil();
    final int maxAmps3Phase = (totalMaxPower / (230 * 1.732))
        .ceil(); // 3-phase calculation
    final int avgAmps1Phase = (totalAvgPower / 230).ceil();
    final int avgAmps3Phase = (totalAvgPower / (230 * 1.732)).ceil();

    // Pixel spacing calculation - show total pixel resolution as W x H
    final int totalPixelsWidth = panelsWidth * led.wPixel;
    final int totalPixelsHeight = panelsHeight * led.hPixel;
    final String pixelSpace = '${totalPixelsWidth} x ${totalPixelsHeight}';

    // Aspect ratio calculation
    final double aspectRatio = actualWidthMeters / actualHeightMeters;
    final String aspectRatioStr = '${aspectRatio.toStringAsFixed(2)}:1';

    // Shipping calculations (basic estimates)
    final int dollysPerCase = 63; // Default estimate
    final double shippingWeight = totalCalculatedWeight * 1.1; // 10% packaging
    final double shippingVolume = sqm * 0.5; // Estimate based on screen area

    // Rigging calculations (basic estimates based on screen size)
    final int trussUpright = (actualWidthMeters / 3).ceil() * 2; // Every 3m
    final int trussBaseplate = trussUpright;
    final int horizontalPipe = (actualWidthMeters / 6).ceil(); // Every 6m
    final int halfCouplers = trussUpright * 4; // 4 per upright
    final int bracingArms = (totalFullPanels / 10).ceil(); // Every 10 panels

    // Cables & Processing (estimates based on panel count)
    final int firstData = (totalFullPanels / 20).ceil() + 6; // Base + extras
    final int firstPower = (totalFullPanels / 15).ceil() + 9; // Base + extras
    final int socapex =
        (totalFullPanels / 25).ceil() + 1; // Based on power distribution
    final int novastarMain = (totalPx / 2000000)
        .ceil(); // 2M pixels per processor
    final int novastarBU = novastarMain; // 1:1 backup ratio

    // Flown rigging (estimates)
    final int singleHeader =
        (actualWidthMeters / 4).ceil() * 9; // Headers every 4m
    final int gacSpanset4m = singleHeader;
    final int shackle25t = singleHeader;

    // Distro calculation
    String distro = 'TBD';
    if (totalKW < 32) {
      distro = '32A - Type 1';
    } else if (totalKW < 63) {
      distro = '63A - Type 1';
    } else if (totalKW < 125) {
      distro = '125A - Type 2';
    } else {
      distro = '125A+ - Type 2';
    }

    return LEDCalculationResult(
      ledName: led.name,
      screenSizeMeters: sqm,
      totalFullPanels: totalFullPanels,
      totalHalfPanels: totalHalfPanels,
      pixelSpace: pixelSpace,
      aspectRatio: aspectRatioStr,
      maxPower: totalMaxPower,
      avgPower: totalAvgPower,
      approxWeight: approxWeightCalc,
      requestedWidth: widthMeters,
      requestedHeight: heightMeters,
      sqm: sqm,
      totalWeight: totalCalculatedWeight,
      totalPx: totalPx,
      dollysPerCase: dollysPerCase,
      shippingWeight: shippingWeight,
      shippingVolume: shippingVolume,
      metersWidth: actualWidthMeters.round(),
      metersHeight: actualHeightMeters.round(),
      panelsWidth: panelsWidth,
      panelsHeight: panelsHeight,
      pixelsWidth: pixelsWidth,
      pixelsHeight: pixelsHeight,
      maxAmps1Phase: maxAmps1Phase,
      maxAmps3Phase: maxAmps3Phase,
      avgAmps1Phase: avgAmps1Phase,
      avgAmps3Phase: avgAmps3Phase,
      totalKW: totalKW,
      kWPerHour: totalKW, // Same as total for hourly
      distro: distro,
      trussUpright: trussUpright,
      trussBaseplate: trussBaseplate,
      horizontalPipe: horizontalPipe,
      halfCouplers: halfCouplers,
      bracingArms: bracingArms,
      firstData: firstData,
      firstPower: firstPower,
      socapex: socapex,
      novastarMain: novastarMain,
      novastarBU: novastarBU,
      screenWeight: screenWeight,
      cableWeight: cableWeight,
      riggingAllowance: riggingAllowance,
      totalCalculatedWeight: totalCalculatedWeight,
      singleHeader: singleHeader,
      gacSpanset4m: gacSpanset4m,
      shackle25t: shackle25t,
    );
  }
}
