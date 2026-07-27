import 'package:flutter/material.dart';

class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage> {
  final List<Map<String, dynamic>> _dummyData = [
    {
      'number': 'KLK-01',
      'name': 'Kozhikode - Mukkam',
      'from': 'Kozhikode',
      'to': 'Mukkam',
      'via': 'Feroke, Kuttikkattoor',
      'firstBus': '05:30 AM',
      'lastBus': '09:15 PM',
      'frequency': '15 mins',
      'status': 'Active',
    },
    {
      'number': 'KLK-02',
      'name': 'Kozhikode - Vadakara',
      'from': 'Kozhikode',
      'to': 'Vadakara',
      'via': 'Balussery, Koyilandy',
      'firstBus': '05:45 AM',
      'lastBus': '09:30 PM',
      'frequency': '20 mins',
      'status': 'Active',
    },
    {
      'number': 'KLK-03',
      'name': 'Kozhikode - Beypore',
      'from': 'Kozhikode',
      'to': 'Beypore',
      'via': 'Feroke',
      'firstBus': '06:00 AM',
      'lastBus': '08:45 PM',
      'frequency': '30 mins',
      'status': 'Active',
    },
    {
      'number': 'KLK-04',
      'name': 'Kozhikode - Meppadi',
      'from': 'Kozhikode',
      'to': 'Meppadi',
      'via': 'Perambra, Thamarassery',
      'firstBus': '08:15 AM',
      'lastBus': '08:30 PM',
      'frequency': '45 mins',
      'status': 'Inactive',
    },
    {
      'number': 'KLK-05',
      'name': 'Kozhikode - Malappuram',
      'from': 'Kozhikode',
      'to': 'Malappuram',
      'via': 'Kondotty',
      'firstBus': '05:30 AM',
      'lastBus': '09:00 PM',
      'frequency': '20 mins',
      'status': 'Active',
    },
    {
      'number': 'KLK-06',
      'name': 'Kozhikode - Wayanad',
      'from': 'Kozhikode',
      'to': 'Kalpetta',
      'via': 'Meppadi',
      'firstBus': '06:30 AM',
      'lastBus': '07:30 PM',
      'frequency': '60 mins',
      'status': 'Inactive',
    },
    {
      'number': 'KLK-07',
      'name': 'Kozhikode - Kannur',
      'from': 'Kozhikode',
      'to': 'Kannur',
      'via': 'Thalassery',
      'firstBus': '05:15 AM',
      'lastBus': '09:45 PM',
      'frequency': '30 mins',
      'status': 'Active',
    },
    {
      'number': 'KLK-08',
      'name': 'Kozhikode - Nilambur',
      'from': 'Kozhikode',
      'to': 'Nilambur',
      'via': 'Kondotty',
      'firstBus': '06:00 AM',
      'lastBus': '08:00 PM',
      'frequency': '45 mins',
      'status': 'Removed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(),
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildTableSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Bus Routes',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Bus Routes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage bus routes, stops, timings and status.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.download_rounded,
                color: Colors.black87,
                size: 20,
              ),
              label: const Text(
                'Export',
                style: TextStyle(color: Colors.black87),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                side: const BorderSide(color: Colors.black12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.black87, size: 20),
              label: const Text(
                'Add Bus Route',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Routes',
            value: '48',
            icon: Icons.directions_bus_filled,
            iconBgColor: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Active Routes',
            value: '38',
            icon: Icons.check_circle_outline,
            iconBgColor: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Inactive Routes',
            value: '6',
            icon: Icons.access_time,
            iconBgColor: Colors.orange.shade50,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Removed Routes',
            value: '4',
            icon: Icons.cancel_outlined,
            iconBgColor: Colors.red.shade50,
            iconColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          _buildDataTable(),
          const Divider(height: 1),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by route name or number...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              hint: const Text('All Status'),
              items:
                  ['Active', 'Inactive', 'Removed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (_) {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              hint: const Text('All Types'),
              items:
                  ['Type A', 'Type B'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (_) {},
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.black54, size: 20),
            label: const Text('Reset', style: TextStyle(color: Colors.black54)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1200, // Fixed width to enable horizontal scrolling
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Route Number
            1: FlexColumnWidth(1.5), // Route Name
            2: FlexColumnWidth(1.0), // From
            3: FlexColumnWidth(1.0), // To
            4: FlexColumnWidth(1.5), // Via
            5: FlexColumnWidth(1.0), // First Bus
            6: FlexColumnWidth(1.0), // Last Bus
            7: FlexColumnWidth(1.0), // Frequency
            8: FlexColumnWidth(1.0), // Status
            9: FlexColumnWidth(1.2), // Actions
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              children: [
                _buildHeaderCell('Route Number'),
                _buildHeaderCell('Route Name'),
                _buildHeaderCell('From'),
                _buildHeaderCell('To'),
                _buildHeaderCell('Via'),
                _buildHeaderCell('First Bus'),
                _buildHeaderCell('Last Bus'),
                _buildHeaderCell('Frequency'),
                _buildHeaderCell('Status'),
                _buildHeaderCell('Actions'),
              ],
            ),
            // Data Rows
            ..._dummyData.map((data) {
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (val) {},
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.black26),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['number'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['name']),
                  _buildDataCell(data['from']),
                  _buildDataCell(data['to']),
                  _buildDataCell(data['via']),
                  _buildDataCell(data['firstBus']),
                  _buildDataCell(data['lastBus']),
                  _buildDataCell(data['frequency']),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildStatusBadge(data['status']),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_red_eye_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Inactive':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'Removed':
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Showing 1 to 8 of 48 entries',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, false),
              const SizedBox(width: 8),
              _buildPageNumber('1', true),
              const SizedBox(width: 8),
              _buildPageNumber('2', false),
              const SizedBox(width: 8),
              _buildPageNumber('3', false),
              const SizedBox(width: 8),
              const Text('...', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              _buildPageNumber('6', false),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, false),
              const SizedBox(width: 16),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Text(
                      '10 / page',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(String number, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFC107) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: isActive ? Colors.black87 : Colors.black54,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, bool isDisabled) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isDisabled ? Colors.black26 : Colors.black54,
      ),
    );
  }
}
