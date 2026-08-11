import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bus_route_model.dart';

class RoutesDataTable extends StatelessWidget {
  final List<BusRouteModel> routes;

  const RoutesDataTable({Key? key, required this.routes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.white),
          headingRowHeight: 54,
          headingTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            fontSize: 15,
          ),
          dataRowMinHeight: 70,
          dataRowMaxHeight: 75,
          columnSpacing: 24,
          horizontalMargin: 24,
          dividerThickness: 1,
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 32,
                child: Icon(
                  Icons.check_box_outline_blank,
                  color: Colors.black26,
                  size: 20,
                ),
              ),
            ),
            DataColumn(label: Text('Route Number')),
            DataColumn(label: Text('Route Name')),
            DataColumn(label: Text('From')),
            DataColumn(label: Text('To')),
            DataColumn(label: Text('Via')),
            DataColumn(label: Text('First Bus')),
            DataColumn(label: Text('Last Bus')),
            DataColumn(label: Text('Frequency')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              routes.map((route) {
                return DataRow(
                  cells: [
                    const DataCell(
                      SizedBox(
                        width: 32,
                        child: Icon(
                          Icons.check_box_outline_blank,
                          color: Colors.black26,
                          size: 20,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.routeNumber,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.routeName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.from,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.to,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.via,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.firstBus,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.lastBus,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        route.frequency,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    DataCell(_buildStatusChip(route.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              color: Colors.black54,
                              size: 20,
                            ),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.black54,
                              size: 20,
                            ),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Active':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Inactive':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'Removed':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
