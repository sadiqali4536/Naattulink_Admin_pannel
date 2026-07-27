import 'package:flutter/material.dart';

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Showing 1 to 8 of 48 entries',
            style: TextStyle(color: Colors.black54, fontSize: 13.0),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, isIcon: true),
              const SizedBox(width: 8),
              _buildPageButton('1', isActive: true),
              const SizedBox(width: 8),
              _buildPageButton('2'),
              const SizedBox(width: 8),
              _buildPageButton('3'),
              const SizedBox(width: 8),
              const Text('...', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              _buildPageButton('6'),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, isIcon: true),
              const SizedBox(width: 24),
              // Items per page dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: '10 / page',
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 16),
                    items: <String>['10 / page', '20 / page', '50 / page'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 13.0)),
                      );
                    }).toList(),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(dynamic content, {bool isActive = false, bool isIcon = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.amber : Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: isActive ? Colors.amber : Colors.grey.shade300),
      ),
      child: Center(
        child: isIcon
            ? Icon(content as IconData, size: 16, color: Colors.black54)
            : Text(
                content as String,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13.0,
                ),
              ),
      ),
    );
  }
}
