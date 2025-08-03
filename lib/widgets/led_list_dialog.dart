import 'package:flutter/material.dart';
import '../models/led_model.dart';
import '../services/led_service.dart';
import 'add_led_dialog_new.dart';

// Text colors as per style guide
const Color textColorPrimary = Color(0xFF383838); // Deep neutral gray for most text
const Color textColorSecondary = Color(0xFFA2A09A); // Light gray for secondary/disabled text

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide (30% darker)
const Color buttonTextColor = Color.fromRGBO(125, 117, 103, 1.0);

class LEDListDialog extends StatefulWidget {
  const LEDListDialog({super.key});

  @override
  State<LEDListDialog> createState() => _LEDListDialogState();
}

class _LEDListDialogState extends State<LEDListDialog> {
  List<LEDModel> leds = [];
  List<LEDModel> filteredLeds = [];
  final _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLEDs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLEDs() async {
    try {
      final loadedLEDs = await LEDService.getAllLEDs();
      setState(() {
        leds = loadedLEDs;
        filteredLeds = loadedLEDs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading LEDs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterLEDs(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredLeds = leds;
      } else {
        filteredLeds = leds
            .where(
              (led) =>
                  led.name.toLowerCase().contains(query.toLowerCase()) ||
                  led.manufacturer.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  led.model.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _deleteLED(LEDModel led) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : const Color(0xFFF7F6F3),
          title: const Text('Delete LED'),
          content: Text('Are you sure you want to delete "${led.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: buttonTextColor),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await LEDService.deleteLED(led.key);
        await _loadLEDs();
        if (mounted) {
          // Removed success notification - keep only error notifications
          // Return true to indicate data was modified
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting LED: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editLED(LEDModel led) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AddLEDDialogNew(existingLED: led);
      },
    );

    // If the edit was successful, reload the LED list and notify parent
    if (result == true) {
      await _loadLEDs();
      if (mounted) {
        // Return true to indicate data was modified
        Navigator.of(context).pop(true);
      }
    }
  }

  Widget _buildLEDCard(LEDModel led) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(led.name, style: const TextStyle(fontSize: 14)),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _editLED(led),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit LED',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteLED(led),
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  tooltip: 'Delete LED',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : const Color(0xFFF7F6F3),
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'LED Products',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search box
            TextField(
              controller: _searchController,
              onChanged: _filterLEDs,
              decoration: const InputDecoration(
                hintText: 'Search LEDs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // LED count
            Row(
              children: [
                Text(
                  'Found ${filteredLeds.length} LED${filteredLeds.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: textColorSecondary),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AddLEDDialogNew();
                      },
                    );
                    if (result == true) {
                      await _loadLEDs();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New LED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBackgroundColor,
                    foregroundColor: buttonTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // LED list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeds.isEmpty
                  ? const Center(
                      child: Text(
                        'No LEDs found',
                        style: TextStyle(fontSize: 16, color: textColorSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLeds.length,
                      itemBuilder: (context, index) {
                        return _buildLEDCard(filteredLeds[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
