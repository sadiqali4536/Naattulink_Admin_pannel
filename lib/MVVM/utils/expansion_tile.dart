import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';

class SubItem {
  final String title;
  final Widget icon;

  SubItem({
    required this.title,
    required this.icon,
  });
}

class CustomExpansionTile extends StatelessWidget {
  final String title;
  final Widget MainIcon;
  final List<SubItem> subItems;
  final String? expandedTile;
  final String selectedTile;
  final Function(String) onTileExpandToggle;
  final Function(String) onItemSelected;
  final Color expandedColor;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.MainIcon,
    required this.subItems,
    required this.expandedTile,
    required this.selectedTile,
    required this.onTileExpandToggle,
    required this.onItemSelected,
    this.expandedColor =  AppColors.gradient1,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedTile == title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onTileExpandToggle(title),
          child: Container(
            color: isExpanded ? expandedColor : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: isExpanded ? Colors.white : Colors.grey,
                  ),
                  child: MainIcon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isExpanded ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isExpanded ? Colors.white : Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...subItems.map((subItem) {
            final isSelected = selectedTile == subItem.title;
            return GestureDetector(
              onTap: () => onItemSelected(subItem.title),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? expandedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 40),
                  child: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconTheme(
                          data: IconThemeData(
                            size: 18,
                            color:
                                isSelected ? Colors.white : Colors.grey[600],
                          ),
                          child: subItem.icon,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          subItem.title,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
