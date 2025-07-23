import 'package:flutter/material.dart';
import '../models/led_model.dart';
import '../services/led_service.dart';
import 'add_led_dialog_new.dart';

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
          title: const Text('Delete LED'),
          content: Text('Are you sure you want to delete "${led.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LED "${led.name}" deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
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
        return AddLEDDialog(existingLED: led);
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AddLEDDialog();
                      },
                    );
                    if (result == true) {
                      await _loadLEDs();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New LED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
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
                        style: TextStyle(fontSize: 16, color: Colors.grey),
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
