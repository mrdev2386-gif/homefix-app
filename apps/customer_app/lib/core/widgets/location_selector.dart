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
    selectedState = widget.initialState;
    selectedDistrict = widget.initialDistrict;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedState,
          hint: const Text('Select State'),
          items: indiaLocations.keys
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
          items: selectedState != null
              ? indiaLocations[selectedState]!
                  .map((district) =>
                      DropdownMenuItem(value: district, child: Text(district)))
                  .toList()
              : [],
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
