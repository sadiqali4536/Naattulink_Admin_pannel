import 'package:flutter/material.dart';

class TaxiDriversPage extends StatefulWidget {
  const TaxiDriversPage({super.key});

  @override
  State<TaxiDriversPage> createState() => _TaxiDriversPageState();
}

class _TaxiDriversPageState extends State<TaxiDriversPage> {
  final List<Map<String, dynamic>> _dummyData = [
    {
      'name': 'Arun Kumar',
      'id': 'ID: TAXI001',
      'phone': '+91 98765 43210',
      'license': 'KL07 2018 1235567',
      'vehicleNumber': 'KL07 CP 1234',
      'vehicleModel': 'Swift Dzire • White',
      'city': 'Kozhikode',
      'joinedOn': '12 Apr 2024',
      'status': 'Active',
      'earnings': '₹18,650',
      'avatarColor': Colors.blue,
    },
    {
      'name': 'Faisal Rahman',
      'id': 'ID: TAXI002',
      'phone': '+91 88991 23456',
      'license': 'KL11 2017 7654321',
      'vehicleNumber': 'KL11 BJ 5678',
      'vehicleModel': 'Innova Crysta • Silver',
      'city': 'Kozhikode',
      'joinedOn': '28 Mar 2024',
      'status': 'Active',
      'earnings': '₹24,320',
      'avatarColor': Colors.green,
    },
    {
      'name': 'Jibin Joseph',
      'id': 'ID: TAXI003',
      'phone': '+91 95678 90123',
      'license': 'KL10 2019 3456789',
      'vehicleNumber': 'KL10 AZ 9876',
      'vehicleModel': 'Ertiga • Grey',
      'city': 'Kozhikode',
      'joinedOn': '05 May 2024',
      'status': 'Pending',
      'earnings': '-',
      'avatarColor': Colors.orange,
    },
    {
      'name': 'Nidheesh N',
      'id': 'ID: TAXI004',
      'phone': '+91 70123 45678',
      'license': 'KL07 2016 9876543',
      'vehicleNumber': 'KL07 CJ 2468',
      'vehicleModel': 'WagonR • White',
      'city': 'Kozhikode',
      'joinedOn': '18 Feb 2024',
      'status': 'Active',
      'earnings': '₹15,920',
      'avatarColor': Colors.purple,
    },
    {
      'name': 'Shafeek T',
      'id': 'ID: TAXI005',
      'phone': '+91 99956 78901',
      'license': 'KL13 2018 4567890',
      'vehicleNumber': 'KL13 AN 1357',
      'vehicleModel': 'Swift Dzire • Silver',
      'city': 'Kozhikode',
      'joinedOn': '22 Jan 2024',
      'status': 'Suspended',
      'earnings': '₹2,450',
      'avatarColor': Colors.teal,
    },
    {
      'name': 'Ramesh Babu',
      'id': 'ID: TAXI006',
      'phone': '+91 80890 12345',
      'license': 'KL09 2017 2345678',
      'vehicleNumber': 'KL09 BC 8642',
      'vehicleModel': 'Innova • White',
      'city': 'Kozhikode',
      'joinedOn': '11 Apr 2024',
      'status': 'Active',
      'earnings': '₹21,780',
      'avatarColor': Colors.indigo,
    },
    {
      'name': 'Sajid Ali',
      'id': 'ID: TAXI007',
      'phone': '+91 81234 56789',
      'license': 'KL12 2019 8765432',
      'vehicleNumber': 'KL12 AV 2469',
      'vehicleModel': 'Xylo • Grey',
      'city': 'Kozhikode',
      'joinedOn': '30 Apr 2024',
      'status': 'Pending',
      'earnings': '-',
      'avatarColor': Colors.brown,
    },
    {
      'name': 'Vishnu Madhav',
      'id': 'ID: TAXI008',
      'phone': '+91 97456 78912',
      'license': 'KL07 2015 1122334',
      'vehicleNumber': 'KL07 CH 7890',
      'vehicleModel': 'Etios • White',
      'city': 'Kozhikode',
      'joinedOn': '15 Dec 2023',
      'status': 'Inactive',
      'earnings': '₹0',
      'avatarColor': Colors.redAccent,
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Taxi Drivers',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage taxi drivers, vehicles and account status.',
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
                'Add Taxi Driver',
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
            title: 'Total Drivers',
            value: '126',
            icon: Icons.people_outline,
            iconBgColor: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Active Drivers',
            value: '98',
            icon: Icons.check_circle_outline,
            iconBgColor: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Pending Approval',
            value: '12',
            icon: Icons.access_time,
            iconBgColor: Colors.orange.shade50,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Inactive / Suspended',
            value: '14',
            icon: Icons.block,
            iconBgColor: Colors.red.shade50,
            iconColor: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Total Vehicles',
            value: '142',
            icon: Icons.directions_car_outlined,
            iconBgColor: Colors.purple.shade50,
            iconColor: Colors.purple,
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
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
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
                  fontSize: 12,
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
                hintText: 'Search by name, phone or license number...',
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
                  ['Active', 'Pending', 'Inactive', 'Suspended'].map((String value) {
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
              hint: const Text('All Vehicle Types'),
              items:
                  ['Sedan', 'SUV', 'Hatchback'].map((String value) {
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
              hint: const Text('All Cities'),
              items:
                  ['Kozhikode', 'Kochi'].map((String value) {
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
        width: 1400, // Fixed width to enable horizontal scrolling
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5), // Driver Details
            1: FlexColumnWidth(1.5), // Phone
            2: FlexColumnWidth(1.5), // License No.
            3: FlexColumnWidth(2.0), // Vehicle Details
            4: FlexColumnWidth(1.0), // City
            5: FlexColumnWidth(1.0), // Joined On
            6: FlexColumnWidth(1.0), // Status
            7: FlexColumnWidth(1.5), // Earnings
            8: FlexColumnWidth(1.2), // Actions
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
                _buildHeaderCellWithCheckbox('Driver Details'),
                _buildHeaderCell('Phone'),
                _buildHeaderCell('License No.'),
                _buildHeaderCell('Vehicle Details'),
                _buildHeaderCell('City'),
                _buildHeaderCell('Joined On'),
                _buildHeaderCell('Status'),
                _buildHeaderCell('Earnings (This Month)'),
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
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: data['avatarColor'],
                          child: Text(
                            data['name'][0],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['id'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['phone']),
                  _buildDataCell(data['license']),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['vehicleNumber'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['vehicleModel'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['city']),
                  _buildDataCell(data['joinedOn']),
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
                  _buildDataCell(data['earnings']),
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

  Widget _buildHeaderCellWithCheckbox(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
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
      case 'Pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Suspended':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'Inactive':
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
            'Showing 1 to 8 of 126 entries',
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
              _buildPageNumber('16', false),
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
