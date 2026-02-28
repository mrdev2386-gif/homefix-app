import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Step2ProfessionalDetails extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step2ProfessionalDetails({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step2ProfessionalDetails> createState() =>
      _Step2ProfessionalDetailsState();
}

class _Step2ProfessionalDetailsState extends State<Step2ProfessionalDetails> {
  late TextEditingController _bioController;
  int? _experienceYears;
  List<String> _selectedSkills = [];
  List<String> _selectedAreas = [];
  List<bool> _workingDays = List.filled(7, false);
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _hasOwnTools = false;

  final List<String> _skillOptions = [
    'Installation',
    'Repair',
    'Maintenance',
    'Troubleshooting',
    'Consultation',
  ];

  final List<String> _areaOptions = [
    'Residential',
    'Commercial',
    'Industrial',
  ];

  final List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(
      text: widget.formData['bio'] ?? '',
    );
    _experienceYears = widget.formData['experienceYears'];
    _selectedSkills = List<String>.from(widget.formData['skills'] ?? []);
    _selectedAreas = List<String>.from(widget.formData['serviceAreas'] ?? []);
    _workingDays =
        List<bool>.from(widget.formData['workingDays'] ?? List.filled(7, false));
    _startTime = widget.formData['startTime'];
    _endTime = widget.formData['endTime'];
    _hasOwnTools = widget.formData['hasOwnTools'] ?? false;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          widget.onDataChanged('startTime', picked);
        } else {
          _endTime = picked;
          widget.onDataChanged('endTime', picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your expertise and availability',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          _buildExperienceSelector(),
          const SizedBox(height: 24),
          _buildSkillsSelector(),
          const SizedBox(height: 24),
          _buildServiceAreasSelector(),
          const SizedBox(height: 24),
          _buildWorkingDaysSelector(),
          const SizedBox(height: 24),
          _buildWorkingHoursSelector(),
          const SizedBox(height: 24),
          _buildToolsToggle(),
          const SizedBox(height: 24),
          _buildBioField(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildExperienceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Years of Experience',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: DropdownButton<int>(
            value: _experienceYears,
            isExpanded: true,
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            hint: Text(
              'Select experience',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9CA3AF),
              ),
            ),
            items: List.generate(31, (i) => i).map((years) {
              return DropdownMenuItem(
                value: years,
                child: Text('$years years'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _experienceYears = value);
                widget.onDataChanged('experienceYears', value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Skills',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skillOptions.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.remove(skill);
                  }
                });
                widget.onDataChanged('skills', _selectedSkills);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE2E8F0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceAreasSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Areas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _areaOptions.map((area) {
            final isSelected = _selectedAreas.contains(area);
            return FilterChip(
              label: Text(area),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAreas.add(area);
                  } else {
                    _selectedAreas.remove(area);
                  }
                });
                widget.onDataChanged('serviceAreas', _selectedAreas);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE2E8F0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkingDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Days',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            return FilterChip(
              label: Text(_dayLabels[index]),
              selected: _workingDays[index],
              onSelected: (selected) {
                setState(() => _workingDays[index] = selected);
                widget.onDataChanged('workingDays', _workingDays);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: _workingDays[index] ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: _workingDays[index]
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE2E8F0),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Hours',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: GestureDetector(
                onTap: () => _selectTime(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _startTime?.format(context) ?? 'Start',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _startTime != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              fit: FlexFit.loose,
              child: GestureDetector(
                onTap: () => _selectTime(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _endTime?.format(context) ?? 'End',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _endTime != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolsToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you have your own tools?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Helps us match you with jobs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          Switch(
            value: _hasOwnTools,
            onChanged: (value) {
              setState(() => _hasOwnTools = value);
              widget.onDataChanged('hasOwnTools', value);
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About You (Optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 4,
            onChanged: (value) => widget.onDataChanged('bio', value),
            decoration: InputDecoration(
              hintText: 'Tell customers about your experience...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
