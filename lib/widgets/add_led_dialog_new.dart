import 'package:flutter/material.dart';
import '../models/led_model.dart';
import '../services/led_service.dart';

class AddLEDDialog extends StatefulWidget {
  final LEDModel? existingLED;
  const AddLEDDialog({super.key, this.existingLED});

  @override
  State<AddLEDDialog> createState() => _AddLEDDialogState();
}

class _AddLEDDialogState extends State<AddLEDDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers for all text fields organized by columns

  // Basic Info
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();

  // Optical Column
  final _pitchController = TextEditingController();
  final _hPixelController = TextEditingController();
  final _wPixelController = TextEditingController();
  final _halfHPixelController = TextEditingController();
  final _halfWPixelController = TextEditingController();
  final _ledConfigurationController = TextEditingController();
  final _brightnessController = TextEditingController();
  final _viewingAngleController = TextEditingController();
  final _refreshRateController = TextEditingController();

  // Physical Column
  final _fullHeightController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _fullPanelWeightController = TextEditingController();
  final _halfHeightController = TextEditingController();
  final _halfWidthController = TextEditingController();
  final _halfPanelWeightController = TextEditingController();
  final _touringFrameController = TextEditingController();
  final _curveCapabilityController = TextEditingController();

  // Environmental Column
  final _ipRatingController = TextEditingController();
  final _operatingVoltageController = TextEditingController();
  final _operatingTempController = TextEditingController();
  final _fullPanelMaxWController = TextEditingController();
  final _fullPanelAvgWController = TextEditingController();
  final _halfPanelMaxWController = TextEditingController();
  final _halfPanelAvgWController = TextEditingController();
  final _verificationController = TextEditingController();

  // Technical Column
  final _powerConnectionController = TextEditingController();
  final _dataConnectionController = TextEditingController();
  final _processingController = TextEditingController();
  final _panelsPerPortController = TextEditingController();
  final _panelsPer16AController = TextEditingController();

  // Other
  final _supplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingLED != null) {
      _populateFields(widget.existingLED!);
    }
  }

  void _populateFields(LEDModel led) {
    // Basic Info
    _nameController.text = led.name;
    _manufacturerController.text = led.manufacturer;
    _modelController.text = led.model;

    // Optical Column
    _pitchController.text = led.pitch > 0 ? led.pitch.toString() : '';
    _hPixelController.text = led.hPixel > 0 ? led.hPixel.toString() : '';
    _wPixelController.text = led.wPixel > 0 ? led.wPixel.toString() : '';
    _halfHPixelController.text = led.halfHPixel > 0
        ? led.halfHPixel.toString()
        : '';
    _halfWPixelController.text = led.halfWPixel > 0
        ? led.halfWPixel.toString()
        : '';
    _ledConfigurationController.text = led.ledConfiguration;
    _brightnessController.text = led.brightness > 0
        ? led.brightness.toString()
        : '';
    _viewingAngleController.text = led.viewingAngle;
    _refreshRateController.text = led.refreshRate > 0
        ? led.refreshRate.toString()
        : '';

    // Physical Column
    _fullHeightController.text = led.fullHeight > 0
        ? led.fullHeight.toString()
        : '';
    _widthController.text = led.width > 0 ? led.width.toString() : '';
    _depthController.text = led.depth > 0 ? led.depth.toString() : '';
    _fullPanelWeightController.text = led.fullPanelWeight > 0
        ? led.fullPanelWeight.toString()
        : '';
    _halfHeightController.text = led.halfHeight > 0
        ? led.halfHeight.toString()
        : '';
    _halfWidthController.text = led.halfWidth > 0
        ? led.halfWidth.toString()
        : '';
    _halfPanelWeightController.text = led.halfPanelWeight > 0
        ? led.halfPanelWeight.toString()
        : '';
    _touringFrameController.text = led.touringFrame;
    _curveCapabilityController.text = led.curveCapability;

    // Environmental Column
    _ipRatingController.text = led.ipRating;
    _operatingVoltageController.text = led.operatingVoltage;
    _operatingTempController.text = led.operatingTemp;
    _fullPanelMaxWController.text = led.fullPanelMaxW > 0
        ? led.fullPanelMaxW.toString()
        : '';
    _fullPanelAvgWController.text = led.fullPanelAvgW > 0
        ? led.fullPanelAvgW.toString()
        : '';
    _halfPanelMaxWController.text = led.halfPanelMaxW > 0
        ? led.halfPanelMaxW.toString()
        : '';
    _halfPanelAvgWController.text = led.halfPanelAvgW > 0
        ? led.halfPanelAvgW.toString()
        : '';
    _verificationController.text = led.verification;

    // Technical Column
    _powerConnectionController.text = led.powerConnection;
    _dataConnectionController.text = led.dataConnection;
    _processingController.text = led.processing;
    _panelsPerPortController.text = led.panelsPerPort > 0
        ? led.panelsPerPort.toString()
        : '';
    _panelsPer16AController.text = led.panelsPer16A > 0
        ? led.panelsPer16A.toString()
        : '';

    // Other
    _supplierController.text = led.supplier;
  }

  @override
  void dispose() {
    _scrollController.dispose();

    // Basic Info
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();

    // Optical Column
    _pitchController.dispose();
    _hPixelController.dispose();
    _wPixelController.dispose();
    _halfHPixelController.dispose();
    _halfWPixelController.dispose();
    _ledConfigurationController.dispose();
    _brightnessController.dispose();
    _viewingAngleController.dispose();
    _refreshRateController.dispose();

    // Physical Column
    _fullHeightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _fullPanelWeightController.dispose();
    _halfHeightController.dispose();
    _halfWidthController.dispose();
    _halfPanelWeightController.dispose();
    _touringFrameController.dispose();
    _curveCapabilityController.dispose();

    // Environmental Column
    _ipRatingController.dispose();
    _operatingVoltageController.dispose();
    _operatingTempController.dispose();
    _fullPanelMaxWController.dispose();
    _fullPanelAvgWController.dispose();
    _halfPanelMaxWController.dispose();
    _halfPanelAvgWController.dispose();
    _verificationController.dispose();

    // Technical Column
    _powerConnectionController.dispose();
    _dataConnectionController.dispose();
    _processingController.dispose();
    _panelsPerPortController.dispose();
    _panelsPer16AController.dispose();

    // Other
    _supplierController.dispose();

    super.dispose();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          isDense: true,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _saveLED() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final led = LEDModel(
        name: _getString(_nameController.text),
        manufacturer: _getString(_manufacturerController.text),
        model: _getString(_modelController.text),
        pitch: _parseDouble(_pitchController.text),
        fullHeight: _parseDouble(_fullHeightController.text),
        halfHeight: _parseDouble(_halfHeightController.text),
        width: _parseDouble(_widthController.text),
        depth: _parseDouble(_depthController.text),
        fullPanelWeight: _parseDouble(_fullPanelWeightController.text),
        halfPanelWeight: _parseDouble(_halfPanelWeightController.text),
        hPixel: _parseInt(_hPixelController.text),
        wPixel: _parseInt(_wPixelController.text),
        halfHPixel: _parseInt(_halfHPixelController.text),
        halfWPixel: _parseInt(_halfWPixelController.text),
        halfWidth: _parseDouble(_halfWidthController.text),
        fullPanelMaxW: _parseDouble(_fullPanelMaxWController.text),
        halfPanelMaxW: _parseDouble(_halfPanelMaxWController.text),
        fullPanelAvgW: _parseDouble(_fullPanelAvgWController.text),
        halfPanelAvgW: _parseDouble(_halfPanelAvgWController.text),
        processing: _getString(_processingController.text),
        brightness: _parseInt(_brightnessController.text),
        viewingAngle: _getString(_viewingAngleController.text),
        refreshRate: _parseInt(_refreshRateController.text),
        ledConfiguration: _getString(_ledConfigurationController.text),
        ipRating: _getString(_ipRatingController.text),
        curveCapability: _getString(_curveCapabilityController.text),
        verification: _getString(_verificationController.text),
        dataConnection: _getString(_dataConnectionController.text),
        powerConnection: _getString(_powerConnectionController.text),
        touringFrame: _getString(_touringFrameController.text),
        supplier: _getString(_supplierController.text),
        operatingVoltage: _getString(_operatingVoltageController.text),
        operatingTemp: _getString(_operatingTempController.text),
        panelsPerPort: _parseInt(_panelsPerPortController.text),
        panelsPer16A: _parseInt(_panelsPer16AController.text),
        dateAdded: widget.existingLED?.dateAdded ?? DateTime.now(),
      );

      if (widget.existingLED != null) {
        await LEDService.updateLED(widget.existingLED!.key, led);
      } else {
        await LEDService.addLED(led);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingLED != null
                  ? 'LED "${led.name}" updated successfully!'
                  : 'LED "${led.name}" added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving LED: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getString(String value) => value.trim();
  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0.0;
  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingLED != null
                      ? 'Edit LED Product'
                      : 'Add New LED Product',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Form with 4-column layout matching LED info box
            Expanded(
              child: Form(
                key: _formKey,
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Basic Information (spanning all columns)
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('Name', _nameController),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Manufacturer',
                                _manufacturerController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField('Model', _modelController),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 4-Column Layout matching LED info box structure
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Column 1: Optical
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: const Text(
                                      'Optical',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    color: Colors.orange,
                                    margin: const EdgeInsets.only(bottom: 10),
                                  ),
                                  _buildTextField(
                                    'Pixel Pitch (mm)',
                                    _pitchController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'H Pixel',
                                          _hPixelController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildTextField(
                                          'W Pixel',
                                          _wPixelController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'Half Panel H Pixel',
                                          _halfHPixelController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildTextField(
                                          'Half Panel W Pixel',
                                          _halfWPixelController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildTextField(
                                    'LED Configuration',
                                    _ledConfigurationController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Brightness (nit)',
                                    _brightnessController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Viewing Angle',
                                    _viewingAngleController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Refresh Rate (Hz)',
                                    _refreshRateController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Column 2: Physical
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: const Text(
                                      'Physical',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    color: Colors.orange,
                                    margin: const EdgeInsets.only(bottom: 10),
                                  ),
                                  _buildTextField(
                                    'Panel Height (mm)',
                                    _fullHeightController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Panel Width (mm)',
                                    _widthController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Panel Depth (mm)',
                                    _depthController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Panel Weight (kg)',
                                    _fullPanelWeightController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'Half Panel Height (mm)',
                                          _halfHeightController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildTextField(
                                          'Half Panel Width (mm)',
                                          _halfWidthController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildTextField(
                                    'Half Panel Weight (kg)',
                                    _halfPanelWeightController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Touring Frame',
                                    _touringFrameController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Curve Capability',
                                    _curveCapabilityController,
                                    isRequired: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Column 3: Environmental
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: const Text(
                                      'Environmental',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    color: Colors.orange,
                                    margin: const EdgeInsets.only(bottom: 10),
                                  ),
                                  _buildTextField(
                                    'IP Rating',
                                    _ipRatingController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Operating Voltage',
                                    _operatingVoltageController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Operating Temperature',
                                    _operatingTempController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Max Power Consumption (W)',
                                    _fullPanelMaxWController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Avg Power Consumption (W)',
                                    _fullPanelAvgWController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'Half Panel Max Power (W)',
                                          _halfPanelMaxWController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildTextField(
                                          'Half Panel Avg Power (W)',
                                          _halfPanelAvgWController,
                                          isNumber: true,
                                          isRequired: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildTextField(
                                    'Verification',
                                    _verificationController,
                                    isRequired: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Column 4: Technical
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: const Text(
                                      'Technical',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    color: Colors.orange,
                                    margin: const EdgeInsets.only(bottom: 10),
                                  ),
                                  _buildTextField(
                                    'Power Connection',
                                    _powerConnectionController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Data Connection',
                                    _dataConnectionController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Processing',
                                    _processingController,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Panels per Port',
                                    _panelsPerPortController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    'Panels per 16A (230V)',
                                    _panelsPer16AController,
                                    isNumber: true,
                                    isRequired: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveLED,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.existingLED != null ? 'Update LED' : 'Add LED',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
