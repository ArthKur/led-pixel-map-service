import 'package:flutter/material.dart';
import '../models/led_model.dart';
import '../services/led_service.dart';

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide
const Color buttonTextColor = Color.fromRGBO(178, 167, 147, 1.0);

// Text colors as per style guide
const Color textColorPrimary = Color(0xFF383838); // Deep neutral gray for most text
const Color textColorSecondary = Color(0xFFA2A09A); // Light gray for secondary/disabled text

class AddLEDDialog extends StatefulWidget {
  final LEDModel? existingLED;
  const AddLEDDialog({super.key, this.existingLED});

  @override
  State<AddLEDDialog> createState() => _AddLEDDialogState();
}

class _AddLEDDialogState extends State<AddLEDDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers for all text fields
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _pitchController = TextEditingController();
  final _fullHeightController = TextEditingController();
  final _halfHeightController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _fullPanelWeightController = TextEditingController();
  final _halfPanelWeightController = TextEditingController();
  final _hPixelController = TextEditingController();
  final _wPixelController = TextEditingController();
  final _fullPanelMaxWController = TextEditingController();
  final _halfPanelMaxWController = TextEditingController();
  final _fullPanelAvgWController = TextEditingController();
  final _halfPanelAvgWController = TextEditingController();
  final _processingController = TextEditingController();
  final _brightnessController = TextEditingController();
  final _viewingAngleController = TextEditingController();
  final _refreshRateController = TextEditingController();
  final _ledConfigurationController = TextEditingController();
  final _ipRatingController = TextEditingController();
  final _curveCapabilityController = TextEditingController();
  final _verificationController = TextEditingController();
  final _dataConnectionController = TextEditingController();
  final _powerConnectionController = TextEditingController();
  final _touringFrameController = TextEditingController();
  final _supplierController = TextEditingController();
  final _operatingVoltageController = TextEditingController();
  final _operatingTempController = TextEditingController();
  final _panelsPerPortController = TextEditingController();
  final _panelsPer16AController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingLED != null) {
      _populateFields(widget.existingLED!);
    }
  }

  void _populateFields(LEDModel led) {
    _nameController.text = led.name;
    _manufacturerController.text = led.manufacturer;
    _modelController.text = led.model;
    _pitchController.text = led.pitch > 0 ? led.pitch.toString() : '';
    _fullHeightController.text = led.fullHeight > 0
        ? led.fullHeight.toString()
        : '';
    _halfHeightController.text = led.halfHeight > 0
        ? led.halfHeight.toString()
        : '';
    _widthController.text = led.width > 0 ? led.width.toString() : '';
    _depthController.text = led.depth > 0 ? led.depth.toString() : '';
    _fullPanelWeightController.text = led.fullPanelWeight > 0
        ? led.fullPanelWeight.toString()
        : '';
    _halfPanelWeightController.text = led.halfPanelWeight > 0
        ? led.halfPanelWeight.toString()
        : '';
    _hPixelController.text = led.hPixel > 0 ? led.hPixel.toString() : '';
    _wPixelController.text = led.wPixel > 0 ? led.wPixel.toString() : '';
    _fullPanelMaxWController.text = led.fullPanelMaxW > 0
        ? led.fullPanelMaxW.toString()
        : '';
    _halfPanelMaxWController.text = led.halfPanelMaxW > 0
        ? led.halfPanelMaxW.toString()
        : '';
    _fullPanelAvgWController.text = led.fullPanelAvgW > 0
        ? led.fullPanelAvgW.toString()
        : '';
    _halfPanelAvgWController.text = led.halfPanelAvgW > 0
        ? led.halfPanelAvgW.toString()
        : '';
    _processingController.text = led.processing;
    _brightnessController.text = led.brightness > 0
        ? led.brightness.toString()
        : '';
    _viewingAngleController.text = led.viewingAngle;
    _refreshRateController.text = led.refreshRate > 0
        ? led.refreshRate.toString()
        : '';
    _ledConfigurationController.text = led.ledConfiguration;
    _ipRatingController.text = led.ipRating;
    _curveCapabilityController.text = led.curveCapability;
    _verificationController.text = led.verification;
    _dataConnectionController.text = led.dataConnection;
    _powerConnectionController.text = led.powerConnection;
    _touringFrameController.text = led.touringFrame;
    _supplierController.text = led.supplier;
    _operatingVoltageController.text = led.operatingVoltage;
    _operatingTempController.text = led.operatingTemp;
    _panelsPerPortController.text = led.panelsPerPort > 0
        ? led.panelsPerPort.toString()
        : '';
    _panelsPer16AController.text = led.panelsPer16A > 0
        ? led.panelsPer16A.toString()
        : '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _pitchController.dispose();
    _fullHeightController.dispose();
    _halfHeightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _fullPanelWeightController.dispose();
    _halfPanelWeightController.dispose();
    _hPixelController.dispose();
    _wPixelController.dispose();
    _fullPanelMaxWController.dispose();
    _halfPanelMaxWController.dispose();
    _fullPanelAvgWController.dispose();
    _halfPanelAvgWController.dispose();
    _processingController.dispose();
    _brightnessController.dispose();
    _viewingAngleController.dispose();
    _refreshRateController.dispose();
    _ledConfigurationController.dispose();
    _ipRatingController.dispose();
    _curveCapabilityController.dispose();
    _verificationController.dispose();
    _dataConnectionController.dispose();
    _powerConnectionController.dispose();
    _touringFrameController.dispose();
    _supplierController.dispose();
    _operatingVoltageController.dispose();
    _operatingTempController.dispose();
    _panelsPerPortController.dispose();
    _panelsPer16AController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  // Helper method to safely parse double values
  double _parseDouble(String value) {
    if (value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  // Helper method to safely parse int values
  int _parseInt(String value) {
    if (value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  // Helper method to get string value or empty string
  String _getString(String value) {
    return value.trim();
  }

  Future<void> _saveLED() async {
    if (_formKey.currentState!.validate()) {
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
          halfHPixel: 0, // Default value for compatibility
          halfWPixel: 0, // Default value for compatibility
          halfWidth: 0.0, // Default value for compatibility
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
          dateAdded: widget.existingLED?.dateAdded ?? DateTime.now(),
          panelsPerPort: _parseInt(_panelsPerPortController.text),
          panelsPer16A: _parseInt(_panelsPer16AController.text),
        );

        if (widget.existingLED != null) {
          // Update existing LED
          await LEDService.updateLED(widget.existingLED!.key, led);
        } else {
          // Add new LED
          await LEDService.addLED(led);
        }

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
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
              content: Text(
                'Error ${widget.existingLED != null ? 'updating' : 'adding'} LED: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : const Color(0xFFF7F6F3),
      child: Container(
        width: 500, // Reduced width for single column layout
        height: 650,
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

            // Form with simplified single column layout
            Expanded(
              child: Form(
                key: _formKey,
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        children: [
                          // Basic Information
                          _buildTextField('Name', _nameController),
                          _buildTextField(
                            'Manufacturer',
                            _manufacturerController,
                          ),
                          _buildTextField('Model', _modelController),

                          const SizedBox(height: 20),

                          // Summary Section Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              'Summary Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          Container(
                            height: 2,
                            color: Colors.orange,
                            margin: const EdgeInsets.only(bottom: 20),
                          ),

                          // Essential LED specifications only
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
                                  'Panel Height (mm)',
                                  _fullHeightController,
                                  isNumber: true,
                                  isRequired: false,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  'Panel Width (mm)',
                                  _widthController,
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
                                  'H Pixel',
                                  _hPixelController,
                                  isNumber: true,
                                  isRequired: false,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                          _buildTextField(
                            'Max Power Consumption (W)',
                            _fullPanelMaxWController,
                            isNumber: true,
                            isRequired: false,
                          ),
                          _buildTextField(
                            'Panel Weight (kg)',
                            _fullPanelWeightController,
                            isNumber: true,
                            isRequired: false,
                          ),

                          const SizedBox(height: 20),

                          // Technical Section Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              'Technical Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          Container(
                            height: 2,
                            color: Colors.orange,
                            margin: const EdgeInsets.only(bottom: 20),
                          ),

                          // Technical fields
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

                          const SizedBox(height: 30),
                        ],
                      ),
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
                    backgroundColor: buttonBackgroundColor,
                    foregroundColor: buttonTextColor,
                  ),
                  child: Text(
                    widget.existingLED != null ? 'Update LED' : 'Add LED',
                    style: const TextStyle(color: buttonTextColor),
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
