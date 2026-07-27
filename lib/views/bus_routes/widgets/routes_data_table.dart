import 'package:flutter/material.dart';
import '../models/bus_route_model.dart';

class RoutesDataTable extends StatelessWidget {
  final List<BusRouteModel> routes;

  const RoutesDataTable({Key? key, required this.routes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Colors.black26, size: 20)),
                _buildHeaderCell('Route Number', flex: 2),
                _buildHeaderCell('Route Name', flex: 3),
                _buildHeaderCell('From', flex: 2),
                _buildHeaderCell('To', flex: 2),
                _buildHeaderCell('Via', flex: 3),
                _buildHeaderCell('First Bus', flex: 2),
                _buildHeaderCell('Last Bus', flex: 2),
                _buildHeaderCell('Frequency', flex: 2),
                _buildHeaderCell('Status', flex: 2),
                _buildHeaderCell('Actions', flex: 2, center: true),
              ],
            ),
          ),
          // Data Rows
          ...routes.map((route) => _buildDataRow(route)).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 13.0,
        ),
      ),
    );
  }

  Widget _buildDataRow(BusRouteModel route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Colors.black26, size: 20)),
          _buildDataCell(route.routeNumber, flex: 2),
          _buildDataCell(route.routeName, flex: 3),
          _buildDataCell(route.from, flex: 2),
          _buildDataCell(route.to, flex: 2),
          _buildDataCell(route.via, flex: 3),
          _buildDataCell(route.firstBus, flex: 2),
          _buildDataCell(route.lastBus, flex: 2),
          _buildDataCell(route.frequency, flex: 2),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusChip(route.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.black54, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13.0,
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
