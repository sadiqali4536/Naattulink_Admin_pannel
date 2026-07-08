import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  DateTimeRange? _selectedDateRange = DateTimeRange(
    start: DateTime(2024, 5, 12),
    end: DateTime(2024, 5, 18),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isLargeScreen = width > 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsGrid(width),
                const SizedBox(height: 24),

                // Middle Section (Trends Line Chart, Service Donut Chart, Activities)
                _buildMiddleSection(isLargeScreen, width),
                const SizedBox(height: 24),

                // Bottom Section (Latest Bookings Table, Top Selling Products)
                _buildBottomSection(isLargeScreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Overview of NaattuLink platform",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDateRange: _selectedDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF10B981),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF1E293B),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedDateRange = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  _selectedDateRange != null
                      ? "${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}"
                      : "Select Date Range",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Widget _buildStatsGrid(double width) {
    int crossAxisCount = 6;
    if (width < 650) {
      crossAxisCount = 2;
    } else if (width < 1000) {
      crossAxisCount = 3;
    } else if (width < 1350) {
      crossAxisCount = 4;
    }

    final double itemWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
    const double itemHeight = 115;
    final double aspectRatio = itemWidth / itemHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio > 0 ? aspectRatio : 1.5,
      ),
      itemBuilder: (context, index) {
        return _getStatsCard(index);
      },
    );
  }

  Widget _getStatsCard(int index) {
    switch (index) {
      case 0:
        return const StatsCard(
          title: "Total Users",
          value: "12,458",
          trendPercentage: "12.5%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.people_alt_rounded,
          iconColor: Color(0xFF6366F1),
          iconBgColor: Color(0xFFEEF2FF),
        );
      case 1:
        return const StatsCard(
          title: "Total Workers",
          value: "1,245",
          trendPercentage: "8.3%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.engineering_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFECFDF5),
        );
      case 2:
        return const StatsCard(
          title: "Pending Approvals",
          value: "47",
          trendPercentage: "5.6%",
          trendPeriod: "from last week",
          isPositiveTrend: false,
          icon: Icons.pending_actions_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
        );
      case 3:
        return const StatsCard(
          title: "Today's Bookings",
          value: "328",
          trendPercentage: "15.2%",
          trendPeriod: "from yesterday",
          isPositiveTrend: true,
          icon: Icons.calendar_today_rounded,
          iconColor: Color(0xFF3B82F6),
          iconBgColor: Color(0xFFEFF6FF),
        );
      case 4:
        return const StatsCard(
          title: "Completed Bookings",
          value: "1,892",
          trendPercentage: "10.1%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.check_circle_outline_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFECFDF5),
        );
      case 5:
        return const StatsCard(
          title: "Cancelled Bookings",
          value: "86",
          trendPercentage: "2.4%",
          trendPeriod: "from last week",
          isPositiveTrend: false,
          icon: Icons.cancel_outlined,
          iconColor: Color(0xFFEF4444),
          iconBgColor: Color(0xFFFEF2F2),
        );
      case 6:
        return const StatsCard(
          title: "Revenue (This Week)",
          value: "₹2,45,680",
          trendPercentage: "18.6%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Color(0xFF8B5CF6),
          iconBgColor: Color(0xFFF5F3FF),
        );
      case 7:
        return const StatsCard(
          title: "Products",
          value: "1,256",
          trendPercentage: "7.4%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.shopping_bag_rounded,
          iconColor: Color(0xFF2563EB),
          iconBgColor: Color(0xFFEFF6FF),
        );
      case 8:
        return const StatsCard(
          title: "Orders (This Week)",
          value: "1,034",
          trendPercentage: "13.7%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.shopping_cart_rounded,
          iconColor: Color(0xFFEA580C),
          iconBgColor: Color(0xFFFFF7ED),
        );
      case 9:
        return const StatsCard(
          title: "Advertisements",
          value: "58",
          trendPercentage: "3.2%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.campaign_rounded,
          iconColor: Color(0xFFEC4899),
          iconBgColor: Color(0xFFFDF2F8),
        );
      case 10:
        return const StatsCard(
          title: "Bus Routes",
          value: "126",
          trendPercentage: "4.8%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.directions_bus_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFF0F9FF),
        );
      case 11:
        return const StatsCard(
          title: "Taxi Drivers",
          value: "532",
          trendPercentage: "6.3%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.local_taxi_rounded,
          iconColor: Color(0xFFEAB308),
          iconBgColor: Color(0xFFFEFCE8),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMiddleSection(bool isLargeScreen, double width) {
    if (isLargeScreen) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: BookingTrendsChart(),
          ),
          SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: ServiceCategoryChart(),
          ),
          SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: RecentActivitiesList(),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const BookingTrendsChart(),
          const SizedBox(height: 24),
          if (width > 750)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ServiceCategoryChart(),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: RecentActivitiesList(),
                ),
              ],
            )
          else ...[
            const ServiceCategoryChart(),
            const SizedBox(height: 24),
            const RecentActivitiesList(),
          ]
        ],
      );
    }
  }

  Widget _buildBottomSection(bool isLargeScreen) {
    if (isLargeScreen) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: LatestBookingsTable(),
          ),
          SizedBox(width: 24),
          Expanded(
            flex: 7,
            child: TopSellingProducts(),
          ),
        ],
      );
    } else {
      return const Column(
        children: [
          LatestBookingsTable(),
          SizedBox(height: 24),
          TopSellingProducts(),
        ],
      );
    }
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String trendPercentage;
  final String trendPeriod;
  final bool isPositiveTrend;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.trendPercentage,
    required this.trendPeriod,
    required this.isPositiveTrend,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositiveTrend ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                trendPercentage,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPositiveTrend ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendPeriod,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingTrendsChart extends StatelessWidget {
  const BookingTrendsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booking Trends",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text(
                      "This Week",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 200,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = 'May 12';
                            break;
                          case 1:
                            text = 'May 13';
                            break;
                          case 2:
                            text = 'May 14';
                            break;
                          case 3:
                            text = 'May 15';
                            break;
                          case 4:
                            text = 'May 16';
                            break;
                          case 5:
                            text = 'May 17';
                            break;
                          case 6:
                            text = 'May 18';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 480),
                      FlSpot(1, 450),
                      FlSpot(2, 620),
                      FlSpot(3, 320),
                      FlSpot(4, 600),
                      FlSpot(5, 480),
                      FlSpot(6, 750),
                    ],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                          const Color(0xFF10B981).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCategoryChart extends StatelessWidget {
  const ServiceCategoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      _ServiceData("Home Cleaning", 28, const Color(0xFF10B981)),
      _ServiceData("Vehicle Cleaning", 18, const Color(0xFF3B82F6)),
      _ServiceData("Garden Services", 14, const Color(0xFFF59E0B)),
      _ServiceData("Pet Grooming", 10, const Color(0xFF8B5CF6)),
      _ServiceData("Interior Cleaning", 10, const Color(0xFF06B6D4)),
      _ServiceData("Room Cleaning", 9, const Color(0xFFEC4899)),
      _ServiceData("Others", 11, const Color(0xFF64748B)),
    ];

    return Container(
      height: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bookings by Service Category",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                startDegreeOffset: -90,
                sections: data.map((d) {
                  return PieChartSectionData(
                    showTitle: false,
                    color: d.color,
                    value: d.percentage.toDouble(),
                    radius: 25,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: data.map((d) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: d.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${d.percentage}%",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  final String name;
  final int percentage;
  final Color color;

  _ServiceData(this.name, this.percentage, this.color);
}

class RecentActivitiesList extends StatelessWidget {
  const RecentActivitiesList({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      _ActivityItem(
        title: "New user registered",
        subtitle: "John Doe joined the platform",
        time: "2 min ago",
        icon: Icons.person_add_rounded,
        color: const Color(0xFF6366F1),
        bgColor: const Color(0xFFEEF2FF),
      ),
      _ActivityItem(
        title: "Worker waiting approval",
        subtitle: "Suresh Kumar submitted documents",
        time: "10 min ago",
        icon: Icons.assignment_ind_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _ActivityItem(
        title: "New booking received",
        subtitle: "Booking #BK12345 received",
        time: "15 min ago",
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      ),
      _ActivityItem(
        title: "Order completed",
        subtitle: "Order #OR67890 delivered",
        time: "30 min ago",
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      ),
      _ActivityItem(
        title: "New product added",
        subtitle: "Organic Rice 5kg added by shop",
        time: "45 min ago",
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFFEC4899),
        bgColor: const Color(0xFFFDF2F8),
      ),
      _ActivityItem(
        title: "New complaint",
        subtitle: "Complaint #CP54321 received",
        time: "1 hr ago",
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEF2F2),
      ),
    ];

    return Container(
      height: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activities",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.time,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final Color bgColor;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class LatestBookingsTable extends StatelessWidget {
  const LatestBookingsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      _BookingRow("#BK12345", "Arun Kumar", "Home Cleaning", "May 18, 2024 10:00 AM", "Pending", "₹1,250"),
      _BookingRow("#BK12344", "Fathima Ali", "Vehicle Cleaning", "May 18, 2024 11:00 AM", "Assigned", "₹850"),
      _BookingRow("#BK12343", "Ramesh Babu", "Garden Services", "May 18, 2024 02:30 PM", "In Progress", "₹1,500"),
      _BookingRow("#BK12342", "Neha Nair", "Pet Grooming", "May 18, 2024 03:00 PM", "Completed", "₹700"),
      _BookingRow("#BK12341", "Sujith K", "Interior Cleaning", "May 17, 2024 09:30 AM", "Cancelled", "₹1,100"),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Bookings",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 750,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.8),
                  3: FlexColumnWidth(2.2),
                  4: FlexColumnWidth(1.2),
                  5: FlexColumnWidth(1.0),
                  6: FlexColumnWidth(0.8),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                    ),
                    children: [
                      _buildHeaderCell("Booking ID"),
                      _buildHeaderCell("Customer"),
                      _buildHeaderCell("Service"),
                      _buildHeaderCell("Date & Time"),
                      _buildHeaderCell("Status"),
                      _buildHeaderCell("Amount"),
                      _buildHeaderCell("Actions"),
                    ],
                  ),
                  ...bookings.map((booking) {
                    return TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            booking.id,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        Text(
                          booking.customer,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          booking.service,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                        ),
                        Text(
                          booking.dateTime,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                        _buildStatusBadge(booking.status),
                        Text(
                          booking.amount,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF64748B)),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case "Pending":
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case "Assigned":
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0284C7);
        break;
      case "In Progress":
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF7C3AED);
        break;
      case "Completed":
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case "Cancelled":
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BookingRow {
  final String id;
  final String customer;
  final String service;
  final String dateTime;
  final String status;
  final String amount;

  _BookingRow(this.id, this.customer, this.service, this.dateTime, this.status, this.amount);
}

class TopSellingProducts extends StatelessWidget {
  const TopSellingProducts({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      _ProductItem("Organic Rice 5kg", 245, "₹73,500", Colors.green[50]!),
      _ProductItem("Sunflower Oil 1L", 189, "₹37,800", Colors.amber[50]!),
      _ProductItem("Farm Fresh Eggs (12)", 156, "₹23,400", Colors.orange[50]!),
      _ProductItem("Fresh Banana 1kg", 142, "₹14,200", Colors.yellow[50]!),
      _ProductItem("Green Tea 100g", 118, "₹11,800", Colors.teal[50]!),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Selling Products",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Product",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Orders",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Revenue",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
              ...products.map((product) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: product.imgBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.orders.toString(),
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                    ),
                    Text(
                      product.revenue,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItem {
  final String name;
  final int orders;
  final String revenue;
  final Color imgBgColor;

  _ProductItem(this.name, this.orders, this.revenue, this.imgBgColor);
}
