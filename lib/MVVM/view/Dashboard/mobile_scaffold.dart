import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Ads%20Promotion/Ads%20Promotion.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Dashboard/Dashboard.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Loyalty%20Points/Loyalty%20Points.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Notifications/Notifications.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Payments/Payments.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Services.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Categories.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/User_roles.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Banned_users.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/All_workers.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/Verification_Worker.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/profile_Worker.dart';

class NotificationItem {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  NotificationItem({
    required this.message,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class MobileScaffold extends StatefulWidget {
  const MobileScaffold({super.key});

  @override
  State<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends State<MobileScaffold> {
  String selectedTile = "Dashboard";
  List<NotificationItem> notifications = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    notifications = [
      NotificationItem(
        message: "User Alex booked a service",
        icon: Icons.book_online,
        color: Colors.green,
        onTap: () => setState(() => selectedTile = "Dashboard"),
      ),
      NotificationItem(
        message: "Booking ID 123 was cancelled",
        icon: Icons.cancel,
        color: Colors.red,
        onTap: () => setState(() => selectedTile = "Dashboard"),
      ),
      NotificationItem(
        message: "New user Sarah joined",
        icon: Icons.person_add,
        color: Colors.blue,
        onTap: () => setState(() => selectedTile = "User Profile"),
      ),
    ];
  }

  Widget getSelectedPage() {
    switch (selectedTile) {
      case "Dashboard":
        return const Dashboard();
      case "Worker Profile":
        return const ProfileWorker();
      case "Verification":
        return const VerificationWorker();
      case "All Workers":
        return AllWorkersPage(
          initialFilter: "All",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Pending Approvals":
        return AllWorkersPage(
          initialFilter: "Pending",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Approved Workers":
        return AllWorkersPage(
          initialFilter: "Approved",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Rejected Workers":
        return AllWorkersPage(
          initialFilter: "Rejected",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Suspended Workers":
        return AllWorkersPage(
          initialFilter: "Suspended",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "User Profile":
        return const ProfileUser();
      case "User Roles":
        return const UserRolesPage();
      case "Banned Users":
        return const BannedUsersPage();
      case "Services":
      case "All Services":
        return const Services();
      case "Categories":
        return const ServiceCategoriesPage();
      case "Service Reviews":
        return _buildPlaceholderPage("Service Reviews", Icons.rate_review_rounded);
      case "Payments":
        return PaymentPage();
      case "All Bookings":
        return Bookings(
          initialFilter: "All",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Pending Bookings":
        return Bookings(
          initialFilter: "Pending",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Confirmed Bookings":
        return Bookings(
          initialFilter: "Confirmed",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Completed Bookings":
        return Bookings(
          initialFilter: "Completed",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Cancelled Bookings":
        return Bookings(
          initialFilter: "Cancelled",
          onTabChanged: (tab) => setState(() => selectedTile = tab),
        );
      case "Loyalty Points":
        return const Loyaltypoints();
      case "Notifications":
        return const Notifications();
      case "Ads Promotion":
        return const Adspromotion();
      case "Products":
        return _buildPlaceholderPage("Products Catalog", Icons.shopping_bag_rounded);
      case "Orders":
        return _buildPlaceholderPage("Orders Management", Icons.shopping_cart_rounded);
      case "Bus Routes":
        return _buildPlaceholderPage("Bus Routes", Icons.directions_bus_rounded);
      case "Taxi Drivers":
        return _buildPlaceholderPage("Taxi Drivers", Icons.local_taxi_rounded);
      case "Coupons":
        return _buildPlaceholderPage("Coupons & Offers", Icons.local_offer_rounded);
      case "Profile":
        return _buildPlaceholderPage("Admin Profile", Icons.person_rounded);
      default:
        return Center(
          child: Text(
            "Selected: $selectedTile",
            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF64748B)),
          ),
        );
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Under development.",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF475569)),
        title: Text(
          "NaattuLink",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, size: 20),
            onPressed: () {
              // Action for mobile search popup
            },
          ),
          TopBarBadgeIcon(
            icon: Icons.notifications_none_rounded,
            count: 5,
            onTap: () => _showNotificationsDialog(context),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'https://randomuser.me/api/portraits/men/32.jpg',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 28,
                  height: 28,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.person, color: Color(0xFF64748B), size: 14),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFE2E8F0), height: 1),
        ),
      ),
      drawer: Drawer(
        width: 280,
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            _buildBrandHeader(),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SidebarTile(
                      title: "Dashboard",
                      icon: Icons.dashboard_rounded,
                      isSelected: selectedTile == "Dashboard",
                      onTap: () {
                        setState(() => selectedTile = "Dashboard");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarExpansionTile(
                      title: "User Management",
                      icon: Icons.people_alt_rounded,
                      isInitiallyExpanded: selectedTile == "User Profile" || selectedTile == "User Roles" || selectedTile == "Banned Users",
                      onTap: () => setState(() => selectedTile = "User Profile"),
                      children: [
                        SidebarTile(
                          title: "Users",
                          icon: Icons.person_outline_rounded,
                          isSelected: selectedTile == "User Profile",
                          onTap: () {
                            setState(() => selectedTile = "User Profile");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "User Roles",
                          icon: Icons.shield_outlined,
                          isSelected: selectedTile == "User Roles",
                          onTap: () {
                            setState(() => selectedTile = "User Roles");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Banned Users",
                          icon: Icons.block_flipped,
                          isSelected: selectedTile == "Banned Users",
                          onTap: () {
                            setState(() => selectedTile = "Banned Users");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarExpansionTile(
                      title: "Worker Management",
                      icon: Icons.engineering_rounded,
                      isInitiallyExpanded: selectedTile == "All Workers" || selectedTile == "Pending Approvals" || selectedTile == "Approved Workers" || selectedTile == "Rejected Workers" || selectedTile == "Suspended Workers",
                      onTap: () => setState(() => selectedTile = "All Workers"),
                      children: [
                        SidebarTile(
                          title: "All Workers",
                          icon: Icons.group_outlined,
                          isSelected: selectedTile == "All Workers",
                          onTap: () {
                            setState(() => selectedTile = "All Workers");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Pending Approvals",
                          icon: Icons.hourglass_empty_rounded,
                          isSelected: selectedTile == "Pending Approvals",
                          onTap: () {
                            setState(() => selectedTile = "Pending Approvals");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "24",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SidebarTile(
                          title: "Approved Workers",
                          icon: Icons.check_circle_outline_rounded,
                          isSelected: selectedTile == "Approved Workers",
                          onTap: () {
                            setState(() => selectedTile = "Approved Workers");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Rejected Workers",
                          icon: Icons.cancel_outlined,
                          isSelected: selectedTile == "Rejected Workers",
                          onTap: () {
                            setState(() => selectedTile = "Rejected Workers");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Suspended Workers",
                          icon: Icons.pause_circle_outline_rounded,
                          isSelected: selectedTile == "Suspended Workers",
                          onTap: () {
                            setState(() => selectedTile = "Suspended Workers");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarExpansionTile(
                      title: "Bookings",
                      icon: Icons.book_online_rounded,
                      isInitiallyExpanded: selectedTile == "All Bookings" || selectedTile == "Pending Bookings" || selectedTile == "Confirmed Bookings" || selectedTile == "Completed Bookings" || selectedTile == "Cancelled Bookings",
                      onTap: () => setState(() => selectedTile = "All Bookings"),
                      children: [
                        SidebarTile(
                          title: "All Bookings",
                          icon: Icons.list_alt_rounded,
                          isSelected: selectedTile == "All Bookings",
                          onTap: () {
                            setState(() => selectedTile = "All Bookings");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Pending Bookings",
                          icon: Icons.hourglass_empty_rounded,
                          isSelected: selectedTile == "Pending Bookings",
                          onTap: () {
                            setState(() => selectedTile = "Pending Bookings");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "18",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SidebarTile(
                          title: "Confirmed Bookings",
                          icon: Icons.check_circle_outline_rounded,
                          isSelected: selectedTile == "Confirmed Bookings",
                          onTap: () {
                            setState(() => selectedTile = "Confirmed Bookings");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Completed Bookings",
                          icon: Icons.assignment_turned_in_outlined,
                          isSelected: selectedTile == "Completed Bookings",
                          onTap: () {
                            setState(() => selectedTile = "Completed Bookings");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Cancelled Bookings",
                          icon: Icons.cancel_outlined,
                          isSelected: selectedTile == "Cancelled Bookings",
                          onTap: () {
                            setState(() => selectedTile = "Cancelled Bookings");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarExpansionTile(
                      title: "Services",
                      icon: Icons.home_repair_service_rounded,
                      isInitiallyExpanded: selectedTile == "All Services" || selectedTile == "Categories" || selectedTile == "Service Reviews",
                      onTap: () => setState(() => selectedTile = "All Services"),
                      children: [
                        SidebarTile(
                          title: "All Services",
                          icon: Icons.list_alt_rounded,
                          isSelected: selectedTile == "All Services",
                          onTap: () {
                            setState(() => selectedTile = "All Services");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Categories",
                          icon: Icons.category_rounded,
                          isSelected: selectedTile == "Categories",
                          onTap: () {
                            setState(() => selectedTile = "Categories");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        SidebarTile(
                          title: "Service Reviews",
                          icon: Icons.rate_review_rounded,
                          isSelected: selectedTile == "Service Reviews",
                          onTap: () {
                            setState(() => selectedTile = "Service Reviews");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarExpansionTile(
                      title: "Products",
                      icon: Icons.shopping_bag_rounded,
                      isInitiallyExpanded: selectedTile == "Products",
                      children: [
                        SidebarTile(
                          title: "Products List",
                          icon: Icons.list_alt_rounded,
                          isSelected: selectedTile == "Products",
                          onTap: () {
                            setState(() => selectedTile = "Products");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarTile(
                      title: "Orders",
                      icon: Icons.shopping_cart_rounded,
                      isSelected: selectedTile == "Orders",
                      onTap: () {
                        setState(() => selectedTile = "Orders");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarTile(
                      title: "Advertisements",
                      icon: Icons.campaign_rounded,
                      isSelected: selectedTile == "Ads Promotion",
                      onTap: () {
                        setState(() => selectedTile = "Ads Promotion");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarExpansionTile(
                      title: "Transport",
                      icon: Icons.local_shipping_rounded,
                      children: [
                        SidebarTile(
                          title: "Overview",
                          icon: Icons.map_outlined,
                          isSelected: selectedTile == "Transport Overview",
                          onTap: () {
                            setState(() => selectedTile = "Transport Overview");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarTile(
                      title: "Bus Routes",
                      icon: Icons.directions_bus_rounded,
                      isSelected: selectedTile == "Bus Routes",
                      onTap: () {
                        setState(() => selectedTile = "Bus Routes");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarTile(
                      title: "Taxi Drivers",
                      icon: Icons.local_taxi_rounded,
                      isSelected: selectedTile == "Taxi Drivers",
                      onTap: () {
                        setState(() => selectedTile = "Taxi Drivers");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarTile(
                      title: "Coupons",
                      icon: Icons.local_offer_rounded,
                      isSelected: selectedTile == "Coupons",
                      onTap: () {
                        setState(() => selectedTile = "Coupons");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarTile(
                      title: "Notifications",
                      icon: Icons.notifications_rounded,
                      isSelected: selectedTile == "Notifications",
                      onTap: () {
                        setState(() => selectedTile = "Notifications");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                    SidebarExpansionTile(
                      title: "Reports",
                      icon: Icons.bar_chart_rounded,
                      children: [
                        SidebarTile(
                          title: "Overview",
                          icon: Icons.trending_up_rounded,
                          isSelected: selectedTile == "Reports Overview",
                          onTap: () {
                            setState(() => selectedTile = "Reports Overview");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarExpansionTile(
                      title: "Settings",
                      icon: Icons.settings_rounded,
                      children: [
                        SidebarTile(
                          title: "Preferences",
                          icon: Icons.tune_rounded,
                          isSelected: selectedTile == "Preferences",
                          onTap: () {
                            setState(() => selectedTile = "Preferences");
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ],
                    ),
                    SidebarTile(
                      title: "Profile",
                      icon: Icons.person_rounded,
                      isSelected: selectedTile == "Profile",
                      onTap: () {
                        setState(() => selectedTile = "Profile");
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            SidebarLogoutTile(
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: getSelectedPage(),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.spa_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NaattuLink",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "Admin Panel",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 70,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                constraints: const BoxConstraints(maxHeight: 350),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(blurRadius: 16, color: Colors.black12, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Notifications",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "New",
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            ),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("No new notifications", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: notifications.map((note) => ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: note.color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(note.icon, color: note.color, size: 14),
                            ),
                            title: Text(note.message, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E293B))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            onTap: () {
                              Navigator.pop(context);
                              note.onTap();
                            },
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text("Logout", style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }
}

class SidebarTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const SidebarTile({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A2F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarExpansionTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isInitiallyExpanded;
  final VoidCallback? onTap;

  const SidebarExpansionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.isInitiallyExpanded = false,
    this.onTap,
  });

  @override
  State<SidebarExpansionTile> createState() => _SidebarExpansionTileState();
}

class _SidebarExpansionTileState extends State<SidebarExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant SidebarExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInitiallyExpanded != widget.isInitiallyExpanded) {
      _isExpanded = widget.isInitiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (widget.onTap != null) {
                widget.onTap!();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Column(
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}

class SidebarLogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const SidebarLogoutTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopBarBadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const TopBarBadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF475569), size: 20),
            if (count > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}