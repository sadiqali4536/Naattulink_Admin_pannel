import 'package:flutter/material.dart';
import 'models/bus_route_model.dart';
import 'widgets/stat_card.dart';
import 'widgets/filter_bar.dart';
import 'widgets/routes_data_table.dart';
import 'widgets/pagination_footer.dart';

class BusRoutesView extends StatelessWidget {
  const BusRoutesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey background like the image
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bus Routes',
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage bus routes, stops, timings and status.',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, color: Colors.black87, size: 20),
                        label: const Text('Export', style: TextStyle(color: Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, color: Colors.black87, size: 20),
                        label: const Text('Add Bus Route', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          backgroundColor: Colors.amber,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Stats Row
              Row(
                children: [
                  StatCard(
                    title: 'Total Routes',
                    count: '48',
                    icon: Icons.directions_bus,
                    iconColor: Colors.blue.shade600,
                    iconBackgroundColor: Colors.blue.shade50,
                  ),
                  StatCard(
                    title: 'Active Routes',
                    count: '38',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green.shade600,
                    iconBackgroundColor: Colors.green.shade50,
                  ),
                  StatCard(
                    title: 'Inactive Routes',
                    count: '6',
                    icon: Icons.access_time,
                    iconColor: Colors.orange.shade600,
                    iconBackgroundColor: Colors.orange.shade50,
                  ),
                  StatCard(
                    title: 'Removed Routes',
                    count: '4',
                    icon: Icons.highlight_off,
                    iconColor: Colors.red.shade600,
                    iconBackgroundColor: Colors.red.shade50,
                  ),
                ],
              ),

              // Filter Bar
              const FilterBar(),

              // Data Table
              RoutesDataTable(routes: dummyBusRoutes),

              // Pagination
              const PaginationFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
