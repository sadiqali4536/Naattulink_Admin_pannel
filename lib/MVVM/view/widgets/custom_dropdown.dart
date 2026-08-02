import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;
  final double borderRadius;
  final Color primaryColor;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.borderRadius = 8.0,
    this.primaryColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
        // The user requested: "Remove the colored outline/border completely... The selected state should be indicated only by the background color, not by an additional border."
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
      ),
      // Set selectedItemBuilder to control how the selected item looks in the main field
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((T item) {
          return Text(
            itemLabelBuilder(item),
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          );
        }).toList();
      },
      items:
          items.map((T item) {
            final isSelected = item == value;
            return DropdownMenuItem<T>(
              value: item,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  itemLabelBuilder(item),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
      onChanged: onChanged,
    );
  }
}
