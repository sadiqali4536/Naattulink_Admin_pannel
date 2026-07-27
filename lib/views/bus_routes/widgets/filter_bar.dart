import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by route name or number...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status Dropdown
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'All Status',
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                  items: <String>['All Status', 'Active', 'Inactive', 'Removed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Types Dropdown
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'All Types',
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                  items: <String>['All Types', 'Express', 'Ordinary'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Reset Button
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.black54),
            label: const Text('Reset', style: TextStyle(color: Colors.black87)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
