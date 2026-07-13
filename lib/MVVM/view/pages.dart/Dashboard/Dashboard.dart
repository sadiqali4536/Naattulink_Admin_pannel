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
            final DateTimeRange? picked =
                await showGeneralDialog<DateTimeRange>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: "Dismiss",
                  barrierColor: Colors.black.withValues(alpha: 0.4),
                  transitionDuration: const Duration(milliseconds: 220),
                  pageBuilder: (context, anim1, anim2) {
                    return PremiumDateRangePickerDialog(
                      initialDateRange: _selectedDateRange,
                    );
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return FadeTransition(
                      opacity: anim1,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                            parent: anim1,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                );
            if (picked != null) {
              setState(() {
                _selectedDateRange = picked;
              });
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 56,
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    _selectedDateRange != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              gradient:
                  _selectedDateRange != null
                      ? const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCBD5E1).withValues(alpha: 0.15),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _selectedDateRange != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color:
                        _selectedDateRange != null
                            ? Colors.white
                            : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date Range",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDateRange == null
                            ? "Select Date Range"
                            : "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedDateRange!.start.month - 1]} ${_selectedDateRange!.start.day.toString().padLeft(2, '0')} • ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedDateRange!.end.month - 1]} ${_selectedDateRange!.end.day.toString().padLeft(2, '0')}",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight:
                              _selectedDateRange == null
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                          color:
                              _selectedDateRange == null
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _selectedDateRange != null
                        ? Icons.check_circle_rounded
                        : Icons.arrow_drop_down_rounded,
                    key: ValueKey(_selectedDateRange != null),
                    color:
                        _selectedDateRange != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
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

    final double itemWidth =
        (width - (crossAxisCount - 1) * 16) / crossAxisCount;
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
          Expanded(flex: 4, child: BookingTrendsChart()),
          SizedBox(width: 24),
          Expanded(flex: 3, child: ServiceCategoryChart()),
          SizedBox(width: 24),
          Expanded(flex: 3, child: RecentActivitiesList()),
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
                Expanded(child: ServiceCategoryChart()),
                SizedBox(width: 24),
                Expanded(child: RecentActivitiesList()),
              ],
            )
          else ...[
            const ServiceCategoryChart(),
            const SizedBox(height: 24),
            const RecentActivitiesList(),
          ],
        ],
      );
    }
  }

  Widget _buildBottomSection(bool isLargeScreen) {
    if (isLargeScreen) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 13, child: LatestBookingsTable()),
          SizedBox(width: 24),
          Expanded(flex: 7, child: TopSellingProducts()),
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
                color:
                    isPositiveTrend
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                trendPercentage,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isPositiveTrend
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
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
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                sections:
                    data.map((d) {
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
            children:
                data.map((d) {
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
      _BookingRow(
        "#BK12345",
        "Arun Kumar",
        "Home Cleaning",
        "May 18, 2024 10:00 AM",
        "Pending",
        "₹1,250",
      ),
      _BookingRow(
        "#BK12344",
        "Fathima Ali",
        "Vehicle Cleaning",
        "May 18, 2024 11:00 AM",
        "Assigned",
        "₹850",
      ),
      _BookingRow(
        "#BK12343",
        "Ramesh Babu",
        "Garden Services",
        "May 18, 2024 02:30 PM",
        "In Progress",
        "₹1,500",
      ),
      _BookingRow(
        "#BK12342",
        "Neha Nair",
        "Pet Grooming",
        "May 18, 2024 03:00 PM",
        "Completed",
        "₹700",
      ),
      _BookingRow(
        "#BK12341",
        "Sujith K",
        "Interior Cleaning",
        "May 17, 2024 09:30 AM",
        "Cancelled",
        "₹1,100",
      ),
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
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
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
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFF1F5F9),
                            width: 1,
                          ),
                        ),
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          booking.service,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          booking.dateTime,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        _buildStatusBadge(booking.status),
                        Text(
                          booking.amount,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
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

  _BookingRow(
    this.id,
    this.customer,
    this.service,
    this.dateTime,
    this.status,
    this.amount,
  );
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
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Product",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Orders",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Revenue",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              ...products.map((product) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
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
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      product.revenue,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
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

class PremiumDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const PremiumDateRangePickerDialog({super.key, this.initialDateRange});

  @override
  State<PremiumDateRangePickerDialog> createState() =>
      _PremiumDateRangePickerDialogState();
}

class _PremiumDateRangePickerDialogState
    extends State<PremiumDateRangePickerDialog> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
    _currentMonth = _startDate ?? DateTime.now();
  }

  String _formatDateString(DateTime? date) {
    if (date == null) return "";
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";
  }

  String _formatHeaderDate(DateTimeRange? range) {
    if (range == null) return "No date selected";
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[range.start.month - 1]} ${range.start.day} – ${months[range.end.month - 1]} ${range.end.day}";
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  String _getMonthName(int month) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayInstance = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final int firstDayOffset = firstDayInstance.weekday % 7;
    final int totalDays = _daysInMonth(_currentMonth);

    final bool hasSelection = _startDate != null && _endDate != null;
    final int daysCount =
        hasSelection ? _endDate!.difference(_startDate!).inDays + 1 : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 18,
      backgroundColor: const Color(0xFFFCFCFD),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFD),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (Gradient) ──────────────────────────────────────────
            Container(
              height: 90,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SELECT DATE RANGE",
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasSelection
                              ? _formatHeaderDate(
                                DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                ),
                              )
                              : "Choose Date Range",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selected Range Summary or Empty State ────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        hasSelection
                            ? Container(
                              key: const ValueKey('summary_selected'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Selected Range",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF065F46),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDateString(_startDate),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF047857),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.arrow_right_alt_rounded,
                                              color: Color(0xFF059669),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDateString(_endDate),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF047857),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "$daysCount Days",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF065F46),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              key: const ValueKey('summary_empty'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2E8F0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF64748B),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Choose a date range",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF1E293B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "Filter reports between any two dates.",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),

                  // ── Month Selector Row ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_getMonthName(_currentMonth.month)} ${_currentMonth.year}",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          _buildNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month - 1,
                                  1,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildNavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month + 1,
                                  1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Calendar Month Card ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map((
                                day,
                              ) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: totalDays + firstDayOffset,
                          itemBuilder: (context, index) {
                            if (index < firstDayOffset) {
                              return const SizedBox.shrink();
                            }
                            final int dayNum = index - firstDayOffset + 1;
                            final DateTime cellDate = DateTime(
                              _currentMonth.year,
                              _currentMonth.month,
                              dayNum,
                            );

                            return _buildDayCell(cellDate, dayNum, now);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ───────────────────────────────────────────
                  Row(
                    children: [
                      if (_startDate != null || _endDate != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          label: Text(
                            "Clear",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              hasSelection
                                  ? () {
                                    Navigator.pop(
                                      context,
                                      DateTimeRange(
                                        start: _startDate!,
                                        end: _endDate!,
                                      ),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            "Apply",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int dayNum, DateTime today) {
    final bool isStart =
        _startDate != null &&
        date.year == _startDate!.year &&
        date.month == _startDate!.month &&
        date.day == _startDate!.day;
    final bool isEnd =
        _endDate != null &&
        date.year == _endDate!.year &&
        date.month == _endDate!.month &&
        date.day == _endDate!.day;
    final bool isSelected = isStart || isEnd;

    final bool inRange =
        _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);

    final bool isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    BoxDecoration? cellDecoration;
    TextStyle textStyle = GoogleFonts.inter(
      fontSize: 12,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.w500,
    );

    if (isSelected) {
      cellDecoration = const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4010B981),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );
    } else if (inRange) {
      cellDecoration = const BoxDecoration(
        color: Color(0x33DCFCE7),
        shape: BoxShape.circle,
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF047857),
        fontWeight: FontWeight.w600,
      );
    } else if (isToday) {
      cellDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF10B981),
        fontWeight: FontWeight.bold,
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (_startDate == null || (_startDate != null && _endDate != null)) {
            _startDate = date;
            _endDate = null;
          } else if (date.isBefore(_startDate!)) {
            _startDate = date;
          } else {
            _endDate = date;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: cellDecoration,
        child: Text(dayNum.toString(), style: textStyle),
      ),
    );
  }
}
