import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';

class CustomTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final double rowHeight;

  const CustomTable({
    super.key,
    required this.headers,
    required this.rows,
    this.rowHeight = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      border: const TableBorder(
        top: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
        left: BorderSide(color: AppColors.border),
        right: BorderSide(color: AppColors.border),
        verticalInside: BorderSide.none,
        horizontalInside: BorderSide(
          color: AppColors.border,
        ),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(color: Colors.white),
          children: headers.map((header) {
            return TableCell(
              child: SizedBox(
                height: rowHeight,
                child: Center(
                  child: Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) {
          return TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: row.map((cell) {
              return TableCell(
                child: SizedBox(
                  height: rowHeight,
                  child: Center(child: Text(cell)),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}