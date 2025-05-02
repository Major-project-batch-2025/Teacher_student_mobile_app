// lib/presentation/student/widgets/section_selector.dart
// Purpose: Widget for selecting different sections in the student view

import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class SectionSelector extends StatelessWidget {
  final String currentSection;
  final List<String> availableSections;
  final Function(String) onSectionChanged;
  
  const SectionSelector({
    Key? key,
    required this.currentSection,
    required this.availableSections,
    required this.onSectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSection,
          isExpanded: true,
          dropdownColor: Colors.grey.shade800,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white,
          ),
          items: availableSections.map((section) {
            return DropdownMenuItem<String>(
              value: section,
              child: Text(
                section,
                style: TextStyle(
                  color: section == currentSection
                      ? AppColors.primary
                      : Colors.white,
                  fontWeight: section == currentSection
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value != currentSection) {
              onSectionChanged(value);
            }
          },
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
          hint: const Text(
            'Select Section',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}