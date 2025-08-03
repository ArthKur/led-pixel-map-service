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
  final int fullPanelsHeight;  // Number of full panel rows
  final int halfPanelsHeight;  // Number of half panel rows
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
    required this.fullPanelsHeight,
    required this.halfPanelsHeight,
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
    final double fullPanelHeightMeters = led.fullHeight / 1000; // Convert mm to m
    final double halfPanelHeightMeters = led.halfHeight / 1000; // Convert mm to m

    // Calculate panels for width (only full panels)
    final int panelsWidth = (widthMeters / panelWidthMeters).ceil();
    
    // Calculate panels for height with half panel optimization
    final double remainingHeight = heightMeters;
    int fullPanelsHeight = 0;
    int halfPanelsHeight = 0;
    double currentHeight = 0.0;
    
    // Algorithm: Try to fit full panels first, then use half panels for remaining space
    while (currentHeight < remainingHeight) {
      double remainingSpace = remainingHeight - currentHeight;
      
      // If we can fit a full panel
      if (remainingSpace >= fullPanelHeightMeters) {
        fullPanelsHeight++;
        currentHeight += fullPanelHeightMeters;
      }
      // If we can fit a half panel and it gets us closer to target
      else if (remainingSpace >= halfPanelHeightMeters && 
               remainingSpace < fullPanelHeightMeters) {
        halfPanelsHeight++;
        currentHeight += halfPanelHeightMeters;
      }
      // If remaining space is too small for even a half panel, add a half panel to reach target
      else {
        halfPanelsHeight++;
        break;
      }
    }
    
    // Total panels calculation
    final int totalFullPanels = panelsWidth * fullPanelsHeight;
    final int totalHalfPanels = panelsWidth * halfPanelsHeight;
    
    // Actual screen dimensions achieved
    final double actualWidthMeters = panelsWidth * panelWidthMeters;
    final double actualHeightMeters = (fullPanelsHeight * fullPanelHeightMeters) + 
                                      (halfPanelsHeight * halfPanelHeightMeters);
    final double sqm = actualWidthMeters * actualHeightMeters; // Based on actual achieved screen size

    // Pixel calculations
    final int pixelsWidth = panelsWidth * led.wPixel;
    final int fullPixelsHeight = fullPanelsHeight * led.hPixel;
    final int halfPixelsHeight = halfPanelsHeight * (led.halfHPixel > 0 ? led.halfHPixel : led.hPixel ~/ 2);
    final int pixelsHeight = fullPixelsHeight + halfPixelsHeight;
    final int totalPx = pixelsWidth * pixelsHeight;

    // Weight calculations (accounting for different panel weights)
    final double fullPanelWeight = led.fullPanelWeight;
    final double halfPanelWeight = led.halfPanelWeight > 0 ? led.halfPanelWeight : led.fullPanelWeight * 0.5;
    final double screenWeight = (totalFullPanels * fullPanelWeight) + (totalHalfPanels * halfPanelWeight);
    final double cableWeight = (screenWeight * 0.1); // 10% rule
    final double riggingAllowance = (screenWeight + cableWeight) * 0.2; // 20% rule
    final double totalCalculatedWeight = screenWeight + cableWeight + riggingAllowance;

    // Approximate weight calculation: total panels × panel weight + 10%
    final double approxWeightCalc = screenWeight * 1.1;

    // Power calculations (accounting for different panel power consumption)
    final double fullPanelMaxW = led.fullPanelMaxW;
    final double halfPanelMaxW = led.halfPanelMaxW > 0 ? led.halfPanelMaxW : led.fullPanelMaxW * 0.5;
    final double fullPanelAvgW = led.fullPanelAvgW;
    final double halfPanelAvgW = led.halfPanelAvgW > 0 ? led.halfPanelAvgW : led.fullPanelAvgW * 0.5;
    
    final double totalMaxPower = (totalFullPanels * fullPanelMaxW) + (totalHalfPanels * halfPanelMaxW);
    final double totalAvgPower = (totalFullPanels * fullPanelAvgW) + (totalHalfPanels * halfPanelAvgW);
    final double totalKW = totalMaxPower / 1000;

    // Electrical calculations (assuming 230V)
    final int maxAmps1Phase = (totalMaxPower / 230).ceil();
    final int maxAmps3Phase = (totalMaxPower / (230 * 1.732))
        .ceil(); // 3-phase calculation
    final int avgAmps1Phase = (totalAvgPower / 230).ceil();
    final int avgAmps3Phase = (totalAvgPower / (230 * 1.732)).ceil();

    // Pixel spacing calculation - show total pixel resolution as W x H
    final int totalPixelsWidth = panelsWidth * led.wPixel;
    final int totalPixelsHeight = pixelsHeight; // Already calculated above
    final String pixelSpace = '$totalPixelsWidth x $totalPixelsHeight';

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
      panelsHeight: fullPanelsHeight + halfPanelsHeight, // Total panel height count
      fullPanelsHeight: fullPanelsHeight,
      halfPanelsHeight: halfPanelsHeight,
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
