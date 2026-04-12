import 'package:flutter/material.dart';
import '../constants/india_locations.dart';

class LocationSelector extends StatefulWidget {
  final String? initialState;
  final String? initialDistrict;
  final Function(String state, String district) onLocationChanged;

  const LocationSelector({
    Key? key,
    this.initialState,
    this.initialDistrict,
    required this.onLocationChanged,
  }) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late String? selectedState;
  late String? selectedDistrict;

  @override
  void initState() {
    super.initState();
    // Normalize state name (capitalize first letter)
    selectedState = _normalizeStateName(widget.initialState);
    // Normalize district name to match the list
    selectedDistrict = _normalizeDistrictName(widget.initialDistrict, selectedState);
    
    // Debug: Print normalized values
    print('🔍 LocationSelector initialized:');
    print('   Initial state: ${widget.initialState} → Normalized: $selectedState');
    print('   Initial district: ${widget.initialDistrict} → Normalized: $selectedDistrict');
  }

  // Normalize state name to match keys in indiaLocations
  String? _normalizeStateName(String? state) {
    if (state == null || state.isEmpty) return null;
    
    // Find matching state (case-insensitive)
    for (final key in indiaLocations.keys) {
      if (key.toLowerCase() == state.toLowerCase()) {
        return key;
      }
    }
    return state;
  }

  // Normalize district name to match the list for the selected state
  String? _normalizeDistrictName(String? district, String? state) {
    if (district == null || district.isEmpty || state == null) return null;
    
    final districts = indiaLocations[state];
    if (districts == null) return null;
    
    // Find matching district (case-insensitive)
    for (final d in districts) {
      if (d.toLowerCase() == district.toLowerCase()) {
        return d;
      }
    }
    return null; // Return null if no match found to avoid dropdown error
  }

  @override
  Widget build(BuildContext context) {
    // Get unique states
    final uniqueStates = indiaLocations.keys.toList();
    
    // Safety check: Ensure selectedState is valid
    if (selectedState != null && !uniqueStates.contains(selectedState)) {
      print('⚠️ Invalid state value: $selectedState, resetting to null');
      selectedState = null;
      selectedDistrict = null;
    }
    
    // Get unique districts for selected state
    final availableDistricts = selectedState != null
        ? indiaLocations[selectedState]!.toSet().toList()
        : <String>[];
    
    // Safety check: Ensure selectedDistrict is valid
    if (selectedDistrict != null && !availableDistricts.contains(selectedDistrict)) {
      print('⚠️ Invalid district value: $selectedDistrict, resetting to null');
      selectedDistrict = null;
    }
    
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedState,
          hint: const Text('Select State'),
          items: uniqueStates
              .map((state) => DropdownMenuItem(value: state, child: Text(state)))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedState = value;
              selectedDistrict = null;
            });
          },
          decoration: InputDecoration(
            labelText: 'State',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedDistrict,
          hint: const Text('Select District'),
          items: availableDistricts
              .map((district) =>
                  DropdownMenuItem(value: district, child: Text(district)))
              .toList(),
          onChanged: selectedState != null
              ? (value) {
                  setState(() => selectedDistrict = value);
                  if (value != null) {
                    widget.onLocationChanged(selectedState!, value);
                  }
                }
              : null,
          decoration: InputDecoration(
            labelText: 'District',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
