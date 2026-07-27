import 'package:flutter/material.dart';

class ReportsOverviewPage extends StatefulWidget {
  const ReportsOverviewPage({super.key});

  @override
  State<ReportsOverviewPage> createState() => _ReportsOverviewPageState();
}

class _ReportsOverviewPageState extends State<ReportsOverviewPage> {
  final List<Map<String, dynamic>> _dummyData = [
    {
      'id': 'RPT-1248',
      'reason': 'Inappropriate Content',
      'reporterName': 'Arun Kumar',
      'reporterPhone': '+91 98765 43210',
      'module': 'Local Ads',
      'target': 'Ad ID: AD-3421',
      'status': 'Under Review',
      'date': '23 May 2024\n10:30 AM',
    },
    {
      'id': 'RPT-1247',
      'reason': 'Fake Information',
      'reporterName': 'Faisal Rahman',
      'reporterPhone': '+91 88991 23456',
      'module': 'Taxi Drivers',
      'target': 'Driver ID: TX-876',
      'status': 'Resolved',
      'date': '23 May 2024\n09:15 AM',
    },
    {
      'id': 'RPT-1246',
      'reason': 'Spam / Misleading',
      'reporterName': 'Jibin Joseph',
      'reporterPhone': '+91 95678 90123',
      'module': 'Local Ads',
      'target': 'Ad ID: AD-3419',
      'status': 'Resolved',
      'date': '22 May 2024\n06:45 PM',
    },
    {
      'id': 'RPT-1245',
      'reason': 'Harassment',
      'reporterName': 'Nidheesh N',
      'reporterPhone': '+91 70123 45678',
      'module': 'Taxi Drivers',
      'target': 'Driver ID: TX-765',
      'status': 'Under Review',
      'date': '22 May 2024\n02:20 PM',
    },
    {
      'id': 'RPT-1244',
      'reason': 'Inappropriate Content',
      'reporterName': 'Shafeek T',
      'reporterPhone': '+91 99956 78901',
      'module': 'Services',
      'target': 'Service ID: SV-234',
      'status': 'Rejected',
      'date': '21 May 2024\n11:05 AM',
    },
    {
      'id': 'RPT-1243',
      'reason': 'Fake Information',
      'reporterName': 'Ramesh Babu',
      'reporterPhone': '+91 80890 12345',
      'module': 'Bus Routes',
      'target': 'Route ID: BR-156',
      'status': 'Resolved',
      'date': '21 May 2024\n09:40 AM',
    },
    {
      'id': 'RPT-1242',
      'reason': 'Other',
      'reporterName': 'Sajid Ali',
      'reporterPhone': '+91 81234 56789',
      'module': 'Payments',
      'target': 'Txn ID: TXN-9987',
      'status': 'Under Review',
      'date': '20 May 2024\n04:10 PM',
    },
    {
      'id': 'RPT-1241',
      'reason': 'Harassment',
      'reporterName': 'Vishnu Madhav',
      'reporterPhone': '+91 97456 78912',
      'module': 'Taxi Drivers',
      'target': 'Driver ID: TX-654',
      'status': 'Rejected',
      'date': '20 May 2024\n01:30 PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 1000;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(isDesktop),
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildLeftPanel()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildRightPanel()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildLeftPanel(),
                      const SizedBox(height: 24),
                      _buildRightPanel(),
                    ],
                  ),
              ],
            ),
          );
        },
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
              'Reports Overview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Monitor and analyze all reports across the platform.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    'May 16, 2024 - May 23, 2024',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
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
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.download_rounded,
                color: Colors.green,
                size: 20,
              ),
              label: const Text(
                'Export Report',
                style: TextStyle(color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                side: const BorderSide(color: Colors.green),
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

  Widget _buildStatsCards(bool isDesktop) {
    List<Widget> cards = [
      _buildStatCard(
        title: 'Total Reports',
        value: '1,248',
        trendText: '+12% from last 7 days',
        isPositive: true,
        icon: Icons.shield_outlined,
        iconBgColor: Colors.green.shade50,
        iconColor: Colors.green,
      ),
      _buildStatCard(
        title: 'Under Review',
        value: '235',
        trendText: '+8% from last 7 days',
        isPositive: true,
        icon: Icons.remove_red_eye_outlined,
        iconBgColor: Colors.orange.shade50,
        iconColor: Colors.orange,
      ),
      _buildStatCard(
        title: 'Resolved',
        value: '892',
        trendText: '+15% from last 7 days',
        isPositive: true,
        icon: Icons.check,
        iconBgColor: Colors.blue.shade50,
        iconColor: Colors.blue,
      ),
      _buildStatCard(
        title: 'Rejected',
        value: '121',
        trendText: '-5% from last 7 days',
        isPositive: false,
        icon: Icons.close,
        iconBgColor: Colors.red.shade50,
        iconColor: Colors.red,
      ),
      _buildStatCard(
        title: 'Unique Reporters',
        value: '678',
        trendText: '+10% from last 7 days',
        isPositive: true,
        icon: Icons.group_outlined,
        iconBgColor: Colors.purple.shade50,
        iconColor: Colors.purple,
      ),
    ];

    if (isDesktop) {
      return Row(
        children:
            cards
                .map(
                  (e) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: e == cards.last ? 0 : 16.0,
                      ),
                      child: e,
                    ),
                  ),
                )
                .toList(),
      );
    } else {
      return Column(
        children:
            cards
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: e,
                  ),
                )
                .toList(),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trendText,
    required bool isPositive,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            trendText,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                hintText: 'Search by reason, reporter or target...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black38,
                  size: 20,
                ),
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
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildDropdown('All Report Types', [
              'Inappropriate Content',
              'Fake Information',
              'Spam',
              'Harassment',
              'Other',
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildDropdown('All Status', [
              'Under Review',
              'Resolved',
              'Rejected',
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildDropdown('All Modules', [
              'Local Ads',
              'Taxi Drivers',
              'Services',
              'Bus Routes',
              'Payments',
            ]),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.black54, size: 18),
            label: const Text(
              'Reset',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildDropdown(String hint, List<String> items) {
    return DropdownButtonFormField<String>(
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
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
      items:
          items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
      onChanged: (_) {},
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1100, // Fixed width for horizontal scrolling
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(0.5), // #
            1: FlexColumnWidth(1.2), // Report ID
            2: FlexColumnWidth(2.0), // Reason
            3: FlexColumnWidth(2.0), // Reported By
            4: FlexColumnWidth(1.2), // Module
            5: FlexColumnWidth(1.5), // Target Details
            6: FlexColumnWidth(1.5), // Status
            7: FlexColumnWidth(1.5), // Reported On
            8: FlexColumnWidth(1.0), // Actions
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              children: [
                _buildHeaderCell('#'),
                _buildHeaderCell('Report ID'),
                _buildHeaderCell('Reason'),
                _buildHeaderCell('Reported By'),
                _buildHeaderCell('Module'),
                _buildHeaderCell('Target Details'),
                _buildHeaderCell('Status'),
                _buildHeaderCell('Reported On'),
                _buildHeaderCell('Actions'),
              ],
            ),
            ...List.generate(_dummyData.length, (index) {
              final data = _dummyData[index];
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                children: [
                  _buildDataCell('${index + 1}'),
                  _buildDataCell(data['id']),
                  _buildDataCell(data['reason']),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['reporterName'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['reporterPhone'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['module']),
                  _buildDataCell(data['target']),
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
                  _buildDataCell(data['date']),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Resolved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Under Review':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          4,
        ), // Square with slight border radius like in screenshot
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
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
            'Showing 1 to 8 of 1,248 entries',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, true),
              const SizedBox(width: 8),
              _buildPageNumber('1', true),
              const SizedBox(width: 8),
              _buildPageNumber('2', false),
              const SizedBox(width: 8),
              _buildPageNumber('3', false),
              const SizedBox(width: 8),
              const Text('...', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              _buildPageNumber('156', false),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, false),
              const SizedBox(width: 16),
              Container(
                height: 32,
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
        color: isActive ? Colors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
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

  Widget _buildRightPanel() {
    return Column(
      children: [
        _buildRightCard(
          title: 'Reports by Status',
          child: _buildDonutChartWidget(),
        ),
        const SizedBox(height: 24),
        _buildRightCard(
          title: 'Reports by Module',
          child: _buildProgressBarsWidget(),
        ),
        const SizedBox(height: 24),
        _buildRightCard(title: 'Reports Trend', child: _buildLineChartWidget()),
      ],
    );
  }

  Widget _buildRightCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDonutChartWidget() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        // Placeholder for Donut chart
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '1,248',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartLegend('Resolved', '892 (71.5%)', Colors.green),
            const SizedBox(height: 12),
            _buildChartLegend('Under Review', '235 (18.8%)', Colors.orange),
            const SizedBox(height: 12),
            _buildChartLegend('Rejected', '121 (9.7%)', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildChartLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 16),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProgressBarsWidget() {
    return Column(
      children: [
        _buildProgressBar('Local Ads', '512 (41%)', 0.41),
        const SizedBox(height: 16),
        _buildProgressBar('Taxi Drivers', '312 (25%)', 0.25),
        const SizedBox(height: 16),
        _buildProgressBar('Services', '218 (17%)', 0.17),
        const SizedBox(height: 16),
        _buildProgressBar('Bus Routes', '134 (11%)', 0.11),
        const SizedBox(height: 16),
        _buildProgressBar('Payments', '72 (6%)', 0.06),
      ],
    );
  }

  Widget _buildProgressBar(String label, String value, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartWidget() {
    // Simple placeholder for the trend chart using basic layout
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '400',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    '300',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    '200',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    '100',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text('0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    // Grid lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (index) =>
                            Container(height: 1, color: Colors.grey.shade200),
                      ),
                    ),
                    // Line placeholder - A simple representation
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(double.infinity, 150),
                        painter: _TrendLinePainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SizedBox(width: 20), // padding for Y axis labels
              Text(
                'May 17',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(width: 8),
              Text(
                'May 18',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(width: 8),
              Text(
                'May 19',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(width: 8),
              Text(
                'May 20',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(width: 8),
              Text(
                'May 21',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(width: 8),
              Text(
                'May 22',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(width: 8),
              Text(
                'May 23',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / 6;

    // Approximate data points matching the screenshot
    final points = [
      Offset(0, size.height * 0.7),
      Offset(stepX, size.height * 0.5),
      Offset(stepX * 2, size.height * 0.45),
      Offset(stepX * 3, size.height * 0.2),
      Offset(stepX * 4, size.height * 0.35),
      Offset(stepX * 5, size.height * 0.35),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = Colors.green;
    for (var point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
