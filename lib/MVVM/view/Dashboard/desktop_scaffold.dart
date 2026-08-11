import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_admin/MVVM/utils/permission_guard.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Ads%20Promotion/Ads%20Promotion.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Dashboard/Dashboard.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Loyalty%20Points/Loyalty%20Points.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Notifications/Notifications.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Payments/Payments.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Services.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bus Routes/bus_routes.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Settings/preferences_settings.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Taxi Drivers/taxi_drivers.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Truck and JCB/truck_and_jcb.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Healthcare/healthcare.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Businesses/businesses.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Reports/reports_overview.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Categories.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/service_reviews.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/AdminProfile/admin_profile.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/User_roles.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Banned_users.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Suspended_users.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Grant_access.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/All_workers.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/Verification_Worker.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/profile_Worker.dart';
import 'package:swiftclean_admin/MVVM/view/loginpage.dart';

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

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  String selectedTile = "Dashboard";
  List<NotificationItem> notifications = [];
  bool _sessionLoaded = false;
  bool _loggedSidebar = false;
  final _session = RbacSession();
  int pendingBookingsCount = 0;
  int ongoingBookingsCount = 0;
  int pendingWorkersCount = 0;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _loadSession();
    _listenToPendingBookings();
    _listenToPendingWorkers();
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

  void _onSessionChanged() {
    if (mounted) {
      setState(() {
        _loggedSidebar = false;
      });
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  Future<void> _loadSession() async {
    _loggedSidebar = false;
    if (!_session.isActive) {
      await _session.loadSession();
    }
    if (mounted) {
      setState(() {
        _sessionLoaded = true;
        if (!_can(Modules.dashboard, Perms.view)) {
          selectedTile = _getFirstPermittedTile();
        }
      });
    }
  }

  void _logSidebarVisibility() {
    if (_loggedSidebar) return;
    _loggedSidebar = true;

    print(
      '[SIDEBAR] Dashboard -> ${_can(Modules.dashboard, Perms.view) ? "Visible" : "Hidden (Missing dashboard.view)"}',
    );

    final hasUserMgmt =
        _can(Modules.userManagement, Perms.view) ||
        _can(Modules.roles, Perms.view) ||
        _can(Modules.userManagement, 'assign_role') ||
        _can(Modules.grantAccess, Perms.view);
    print(
      '[SIDEBAR] User Management -> ${hasUserMgmt ? "Visible" : "Hidden (Missing user_management.view)"}',
    );

    print(
      '[SIDEBAR] Worker Management -> ${_can(Modules.workerManagement, Perms.view) ? "Visible" : "Hidden (Missing worker_management.view)"}',
    );
    print(
      '[SIDEBAR] Services -> ${_can(Modules.services, Perms.view) ? "Visible" : "Hidden (Missing services.view)"}',
    );
    print(
      '[SIDEBAR] Advertisements -> ${_can(Modules.advertisement, Perms.view) ? "Visible" : "Hidden (Missing advertisement.view)"}',
    );
    print(
      '[SIDEBAR] Bus Routes -> ${_can(Modules.bus, Perms.view) ? "Visible" : "Hidden (Missing bus.view)"}',
    );
    print(
      '[SIDEBAR] Taxi Drivers -> ${_can(Modules.taxi, Perms.view) ? "Visible" : "Hidden (Missing taxi.view)"}',
    );
    print(
      '[SIDEBAR] Truck & JCB -> ${_can(Modules.truck, Perms.view) ? "Visible" : "Hidden (Missing truck.view)"}',
    );
    print(
      '[SIDEBAR] Healthcare -> ${_can(Modules.healthcare, Perms.view) ? "Visible" : "Hidden (Missing healthcare.view)"}',
    );
    print(
      '[SIDEBAR] Businesses -> ${_can(Modules.business, Perms.view) ? "Visible" : "Hidden (Missing business.view)"}',
    );
  }

  String _getFirstPermittedTile() {
    if (_can(Modules.dashboard, Perms.view)) return "Dashboard";
    if (_can(Modules.userManagement, Perms.view)) return "User Profile";
    if (_can(Modules.roles, Perms.view) ||
        _can(Modules.userManagement, 'assign_role'))
      return "User Roles";
    if (_can(Modules.grantAccess, Perms.view)) return "Grant Access";
    if (_can(Modules.workerManagement, Perms.view)) return "All Workers";
    if (_can(Modules.bookings, Perms.view)) return "All Bookings";
    if (_can(Modules.services, Perms.view)) return "All Services";
    if (_can(Modules.advertisement, Perms.view)) return "Ads Promotion";
    if (_can(Modules.payments, Perms.view)) return "Payments";
    if (_can(Modules.bus, Perms.view)) return "Bus Routes";
    if (_can(Modules.taxi, Perms.view)) return "Taxi Drivers";
    if (_can(Modules.truck, Perms.view)) return "Truck & JCB";
    if (_can(Modules.healthcare, Perms.view)) return "Healthcare";
    if (_can(Modules.business, Perms.view)) return "Businesses";
    if (_can(Modules.notifications, Perms.view)) return "Notifications";
    if (_can(Modules.reports, Perms.view)) return "Reports";
    if (_can(Modules.settings, Perms.view)) return "Settings";
    return "Profile";
  }

  void _listenToPendingWorkers() {
    FirebaseFirestore.instance
        .collection("workers")
        .where("isVerified", isEqualTo: 0)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              pendingWorkersCount = snapshot.docs.length;
            });
          }
        });
  }

  void _listenToPendingBookings() {
    FirebaseFirestore.instance
        .collection('service_bookings')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            int pCount = 0;
            int oCount = 0;
            for (var doc in snapshot.docs) {
              final bookingStatus =
                  (doc.data()['booking_status'] ?? doc.data()['status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
              final workStatus =
                  (doc.data()['work_status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
              final completedStatus =
                  (doc.data()['completed_status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

              if (bookingStatus == 'confirmed' && workStatus == 'pending') {
                pCount++;
              }
              if (bookingStatus == 'confirmed' &&
                  workStatus == 'accepted' &&
                  completedStatus == 'ongoing') {
                oCount++;
              }
            }
            setState(() {
              pendingBookingsCount = pCount;
              ongoingBookingsCount = oCount;
            });
          }
        });
  }

  bool _can(String module, String action) =>
      _session.hasPermission(module, action);

  Widget getSelectedPage() {
    switch (selectedTile) {
      case "Dashboard":
        return PermissionGuard(
          module: Modules.dashboard,
          action: Perms.view,
          child: const Dashboard(),
        );
      case "Settings":
        return PermissionGuard(
          module: Modules.settings,
          action: Perms.view,
          child: const PreferencesSettingsPage(),
        );
      case "Worker Profile":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: Perms.view,
          child: const ProfileWorker(),
        );
      case "Verification":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: Perms.view,
          child: const VerificationWorker(),
        );
      case "All Workers":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: Perms.view,
          child: AllWorkersPage(
            initialFilter: "All",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Pending Approvals":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: 'approve_worker',
          child: AllWorkersPage(
            initialFilter: "Pending",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Approved Workers":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: 'approve_worker',
          child: AllWorkersPage(
            initialFilter: "Approved",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Rejected Workers":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: 'reject_worker',
          child: AllWorkersPage(
            initialFilter: "Rejected",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Suspended Workers":
        return PermissionGuard(
          module: Modules.workerManagement,
          action: 'suspend_worker',
          child: AllWorkersPage(
            initialFilter: "Suspended",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "User Profile":
        return PermissionGuard(
          module: Modules.userManagement,
          action: Perms.view,
          child: const ProfileUser(),
        );
      case "User Roles":
        return PermissionGuard(
          module: Modules.roles,
          action: Perms.view,
          hasAccessOverride:
              _can(Modules.roles, Perms.view) ||
              _can(Modules.userManagement, 'assign_role'),
          child: UserRolesPage(
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Banned Users":
        return PermissionGuard(
          module: Modules.userManagement,
          action: 'ban_user',
          child: const BannedUsersPage(),
        );
      case "Suspended Users":
        return PermissionGuard(
          module: Modules.userManagement,
          action: 'suspend_user',
          child: const SuspendedUsersPage(),
        );
      case "Grant Access":
        return PermissionGuard(
          module: Modules.grantAccess,
          action: Perms.view,
          child: GrantAccessPage(
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Services":
      case "All Services":
        return PermissionGuard(
          module: Modules.services,
          action: Perms.view,
          child: const Services(),
        );
      case "Categories":
        return PermissionGuard(
          module: Modules.services,
          action: Perms.view,
          child: const ServiceCategoriesPage(),
        );
      case "Service Reviews":
        return PermissionGuard(
          module: Modules.services,
          action: Perms.view,
          child: const ServiceReviewsPage(),
        );
      case "Payments":
        return PermissionGuard(
          module: Modules.payments,
          action: Perms.view,
          child: PaymentPage(),
        );
      case "All Bookings":
        return PermissionGuard(
          module: Modules.bookings,
          action: Perms.view,
          child: Bookings(
            initialFilter: "All",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Pending Bookings":
        return PermissionGuard(
          module: Modules.bookings,
          action: Perms.view,
          child: Bookings(
            initialFilter: "Pending",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Confirmed Bookings":
        return PermissionGuard(
          module: Modules.bookings,
          action: Perms.view,
          child: Bookings(
            initialFilter: "Confirmed",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "On Going Works":
        return PermissionGuard(
          module: Modules.bookings,
          action: Perms.view,
          child: Bookings(
            initialFilter: "Ongoing",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Completed Bookings":
        return PermissionGuard(
          module: Modules.bookings,
          action: Perms.view,
          child: Bookings(
            initialFilter: "Completed",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Cancelled Bookings":
        return PermissionGuard(
          module: Modules.bookings,
          action: Perms.view,
          child: Bookings(
            initialFilter: "Cancelled",
            onTabChanged: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Loyalty Points":
        return const Loyaltypoints();
      case "Notifications":
        return PermissionGuard(
          module: Modules.notifications,
          action: Perms.view,
          child: const Notifications(),
        );
      case "Ads Promotion":
        return PermissionGuard(
          module: Modules.advertisement,
          action: Perms.view,
          child: const Adspromotion(),
        );
      case "Products":
        return _buildPlaceholderPage(
          "Products Catalog",
          Icons.shopping_bag_rounded,
        );
      case "Orders":
        return _buildPlaceholderPage(
          "Orders Management",
          Icons.shopping_cart_rounded,
        );
      case "Bus Routes":
        return PermissionGuard(
          module: Modules.bus,
          action: Perms.view,
          child: const BusRoutesPage(),
        );
      case "Taxi Drivers":
        return PermissionGuard(
          module: Modules.taxi,
          action: Perms.view,
          child: const TaxiDriversPage(),
        );
      case "Truck & JCB":
        return PermissionGuard(
          module: Modules.truck,
          action: Perms.view,
          child: const TruckAndJcbPage(),
        );
      case "Healthcare":
        return PermissionGuard(
          module: Modules.healthcare,
          action: Perms.view,
          child: const HealthcarePage(),
        );
      case "Businesses":
        return PermissionGuard(
          module: Modules.business,
          action: Perms.view,
          child: const BusinessesPage(),
        );

      case "Coupons":
        return _buildPlaceholderPage(
          "Coupons & Offers",
          Icons.local_offer_rounded,
        );
      case "Profile":
        return const AdminProfilePage();
      case "Reports":
        return PermissionGuard(
          module: Modules.reports,
          action: Perms.view,
          child: const ReportsOverviewPage(),
        );
      default:
        return Center(
          child: Text(
            "Selected: $selectedTile",
            style: GoogleFonts.inter(
              fontSize: 18,
              color: const Color(0xFF64748B),
            ),
          ),
        );
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This section is currently under development.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFC107)),
        ),
      );
    }
    _logSidebarVisibility();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            height: double.infinity,
            color: const Color(0xFF0F172A), // Slate 900
            child: SafeArea(
              child: Column(
                children: [
                  // Brand Header
                  _buildBrandHeader(),
                  const SizedBox(height: 16),

                  // Sidebar Menu Items
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_can(Modules.dashboard, Perms.view))
                            SidebarTile(
                              title: "Dashboard",
                              icon: Icons.dashboard_rounded,
                              isSelected: selectedTile == "Dashboard",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Dashboard",
                                  ),
                            ),
                          // ── User Management ──────────────────────────────────────
                          if (_can(Modules.userManagement, Perms.view) ||
                              _can(Modules.roles, Perms.view) ||
                              _can(Modules.grantAccess, Perms.view))
                            SidebarExpansionTile(
                              title: "User Management",
                              icon: Icons.people_alt_rounded,
                              isInitiallyExpanded:
                                  selectedTile == "User Profile" ||
                                  selectedTile == "User Roles" ||
                                  selectedTile == "Banned Users" ||
                                  selectedTile == "Suspended Users" ||
                                  selectedTile == "Grant Access",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "User Profile",
                                  ),
                              children: [
                                if (_can(Modules.userManagement, Perms.view))
                                  SidebarTile(
                                    title: "Users",
                                    icon: Icons.person_outline_rounded,
                                    isSelected: selectedTile == "User Profile",
                                    onTap:
                                        () => setState(
                                          () => selectedTile = "User Profile",
                                        ),
                                  ),
                                if (_can(Modules.roles, Perms.view) ||
                                    _can(Modules.userManagement, 'assign_role'))
                                  SidebarTile(
                                    title: "User Roles",
                                    icon: Icons.shield_outlined,
                                    isSelected: selectedTile == "User Roles",
                                    onTap:
                                        () => setState(
                                          () => selectedTile = "User Roles",
                                        ),
                                  ),
                                if (_can(Modules.userManagement, 'ban_user'))
                                  SidebarTile(
                                    title: "Banned Users",
                                    icon: Icons.block_flipped,
                                    isSelected: selectedTile == "Banned Users",
                                    onTap:
                                        () => setState(
                                          () => selectedTile = "Banned Users",
                                        ),
                                  ),
                                if (_can(
                                  Modules.userManagement,
                                  'suspend_user',
                                ))
                                  SidebarTile(
                                    title: "Suspended Users",
                                    icon: Icons.pause_circle_outline,
                                    isSelected:
                                        selectedTile == "Suspended Users",
                                    onTap:
                                        () => setState(
                                          () =>
                                              selectedTile = "Suspended Users",
                                        ),
                                  ),
                                if (_can(Modules.grantAccess, Perms.view))
                                  SidebarTile(
                                    title: "Grant Access",
                                    icon: Icons.admin_panel_settings_rounded,
                                    isSelected: selectedTile == "Grant Access",
                                    onTap:
                                        () => setState(
                                          () => selectedTile = "Grant Access",
                                        ),
                                  ),
                              ],
                            ),
                          // ── Worker Management ─────────────────────────────────────
                          if (_can(Modules.workerManagement, Perms.view) ||
                              _can(
                                Modules.workerManagement,
                                'approve_worker',
                              ) ||
                              _can(Modules.workerManagement, 'reject_worker') ||
                              _can(Modules.workerManagement, 'suspend_worker'))
                            SidebarExpansionTile(
                              title: "Worker Management",
                              icon: Icons.engineering_rounded,
                              isInitiallyExpanded:
                                  selectedTile == "All Workers" ||
                                  selectedTile == "Pending Approvals" ||
                                  selectedTile == "Approved Workers" ||
                                  selectedTile == "Rejected Workers" ||
                                  selectedTile == "Suspended Workers",
                              trailing:
                                  pendingWorkersCount > 0
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          pendingWorkersCount.toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      : null,
                              onTap:
                                  () => setState(
                                    () => selectedTile = "All Workers",
                                  ),
                              children: [
                                if (_can(Modules.workerManagement, Perms.view))
                                  SidebarTile(
                                    title: "All Workers",
                                    icon: Icons.group_outlined,
                                    isSelected: selectedTile == "All Workers",
                                    onTap:
                                        () => setState(
                                          () => selectedTile = "All Workers",
                                        ),
                                  ),
                                if (_can(
                                  Modules.workerManagement,
                                  'approve_worker',
                                ))
                                  SidebarTile(
                                    title: "Pending Approvals",
                                    icon: Icons.hourglass_empty_rounded,
                                    isSelected:
                                        selectedTile == "Pending Approvals",
                                    onTap:
                                        () => setState(
                                          () =>
                                              selectedTile =
                                                  "Pending Approvals",
                                        ),
                                    trailing: StreamBuilder<QuerySnapshot>(
                                      stream:
                                          FirebaseFirestore.instance
                                              .collection("workers")
                                              .where("isVerified", isEqualTo: 0)
                                              .snapshots(),
                                      builder: (context, snapshot) {
                                        int count = 0;
                                        if (snapshot.hasData) {
                                          count = snapshot.data!.docs.length;
                                        }
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            count.toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (_can(
                                  Modules.workerManagement,
                                  'approve_worker',
                                ))
                                  SidebarTile(
                                    title: "Approved Workers",
                                    icon: Icons.check_circle_outline_rounded,
                                    isSelected:
                                        selectedTile == "Approved Workers",
                                    onTap:
                                        () => setState(
                                          () =>
                                              selectedTile = "Approved Workers",
                                        ),
                                  ),
                                if (_can(
                                  Modules.workerManagement,
                                  'reject_worker',
                                ))
                                  SidebarTile(
                                    title: "Rejected Workers",
                                    icon: Icons.cancel_outlined,
                                    isSelected:
                                        selectedTile == "Rejected Workers",
                                    onTap:
                                        () => setState(
                                          () =>
                                              selectedTile = "Rejected Workers",
                                        ),
                                  ),
                                if (_can(
                                  Modules.workerManagement,
                                  'suspend_worker',
                                ))
                                  SidebarTile(
                                    title: "Suspended Workers",
                                    icon: Icons.pause_circle_outline_rounded,
                                    isSelected:
                                        selectedTile == "Suspended Workers",
                                    onTap:
                                        () => setState(
                                          () =>
                                              selectedTile =
                                                  "Suspended Workers",
                                        ),
                                  ),
                              ],
                            ),
                          // ── Bookings ───────────────────────────────────────────────
                          if (_can(Modules.bookings, Perms.view))
                            SidebarExpansionTile(
                              title: "Bookings",
                              icon: Icons.book_online_rounded,
                              isInitiallyExpanded:
                                  selectedTile == "All Bookings" ||
                                  selectedTile == "Pending Bookings" ||
                                  selectedTile == "On Going Works" ||
                                  selectedTile == "Completed Bookings" ||
                                  selectedTile == "Cancelled Bookings",
                              trailing:
                                  pendingBookingsCount > 0
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          pendingBookingsCount.toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      : null,
                              onTap:
                                  () => setState(
                                    () => selectedTile = "All Bookings",
                                  ),
                              children: [
                                SidebarTile(
                                  title: "All Bookings",
                                  icon: Icons.list_alt_rounded,
                                  isSelected: selectedTile == "All Bookings",
                                  onTap:
                                      () => setState(
                                        () => selectedTile = "All Bookings",
                                      ),
                                ),
                                SidebarTile(
                                  title: "Pending Bookings",
                                  icon: Icons.hourglass_empty_rounded,
                                  isSelected:
                                      selectedTile == "Pending Bookings",
                                  onTap:
                                      () => setState(
                                        () => selectedTile = "Pending Bookings",
                                      ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      pendingBookingsCount.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SidebarTile(
                                  title: "On Going Works",
                                  icon: Icons.play_circle_outline_rounded,
                                  isSelected: selectedTile == "On Going Works",
                                  onTap:
                                      () => setState(
                                        () => selectedTile = "On Going Works",
                                      ),
                                  trailing:
                                      ongoingBookingsCount > 0
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B5CF6),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              ongoingBookingsCount.toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                                SidebarTile(
                                  title: "Completed Bookings",
                                  icon: Icons.assignment_turned_in_outlined,
                                  isSelected:
                                      selectedTile == "Completed Bookings",
                                  onTap:
                                      () => setState(
                                        () =>
                                            selectedTile = "Completed Bookings",
                                      ),
                                ),
                                SidebarTile(
                                  title: "Cancelled Bookings",
                                  icon: Icons.cancel_outlined,
                                  isSelected:
                                      selectedTile == "Cancelled Bookings",
                                  onTap:
                                      () => setState(
                                        () =>
                                            selectedTile = "Cancelled Bookings",
                                      ),
                                ),
                              ],
                            ),
                          // ── Services ───────────────────────────────────────────────
                          if (_can(Modules.services, Perms.view))
                            SidebarExpansionTile(
                              title: "Services",
                              icon: Icons.home_repair_service_rounded,
                              isInitiallyExpanded:
                                  selectedTile == "All Services" ||
                                  selectedTile == "Categories" ||
                                  selectedTile == "Service Reviews",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "All Services",
                                  ),
                              children: [
                                SidebarTile(
                                  title: "All Services",
                                  icon: Icons.list_alt_rounded,
                                  isSelected: selectedTile == "All Services",
                                  onTap:
                                      () => setState(
                                        () => selectedTile = "All Services",
                                      ),
                                ),
                                SidebarTile(
                                  title: "Categories",
                                  icon: Icons.category_rounded,
                                  isSelected: selectedTile == "Categories",
                                  onTap:
                                      () => setState(
                                        () => selectedTile = "Categories",
                                      ),
                                ),
                                SidebarTile(
                                  title: "Service Reviews",
                                  icon: Icons.rate_review_rounded,
                                  isSelected: selectedTile == "Service Reviews",
                                  onTap:
                                      () => setState(
                                        () => selectedTile = "Service Reviews",
                                      ),
                                ),
                              ],
                            ),
                          // ── Ads / Payments / Reports / Settings ────────────────────
                          if (_can(Modules.advertisement, Perms.view))
                            SidebarTile(
                              title: "Advertisements",
                              icon: Icons.campaign_rounded,
                              isSelected: selectedTile == "Ads Promotion",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Ads Promotion",
                                  ),
                            ),
                          if (_can(Modules.payments, Perms.view))
                            SidebarTile(
                              title: "Payments",
                              icon: Icons.payments_outlined,
                              isSelected: selectedTile == "Payments",
                              onTap:
                                  () =>
                                      setState(() => selectedTile = "Payments"),
                            ),
                          if (_can(Modules.bus, Perms.view))
                            SidebarTile(
                              title: "Bus Routes",
                              icon: Icons.directions_bus_rounded,
                              isSelected: selectedTile == "Bus Routes",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Bus Routes",
                                  ),
                            ),
                          if (_can(Modules.taxi, Perms.view))
                            SidebarTile(
                              title: "Taxi Drivers",
                              icon: Icons.local_taxi_rounded,
                              isSelected: selectedTile == "Taxi Drivers",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Taxi Drivers",
                                  ),
                            ),
                          if (_can(Modules.truck, Perms.view))
                            SidebarTile(
                              title: "Truck & JCB",
                              icon: Icons.fire_truck_rounded,
                              isSelected: selectedTile == "Truck & JCB",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Truck & JCB",
                                  ),
                            ),
                          if (_can(Modules.healthcare, Perms.view))
                            SidebarTile(
                              title: "Healthcare",
                              icon: Icons.local_hospital_rounded,
                              isSelected: selectedTile == "Healthcare",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Healthcare",
                                  ),
                            ),
                          if (_can(Modules.business, Perms.view))
                            SidebarTile(
                              title: "Businesses",
                              icon: Icons.store_rounded,
                              isSelected: selectedTile == "Businesses",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Businesses",
                                  ),
                            ),
                          if (_can(Modules.notifications, Perms.view))
                            SidebarTile(
                              title: "Notifications",
                              icon: Icons.notifications_rounded,
                              isSelected: selectedTile == "Notifications",
                              onTap:
                                  () => setState(
                                    () => selectedTile = "Notifications",
                                  ),
                            ),
                          if (_can(Modules.reports, Perms.view))
                            SidebarTile(
                              title: "Reports",
                              icon: Icons.bar_chart_rounded,
                              isSelected: selectedTile == "Reports",
                              onTap:
                                  () =>
                                      setState(() => selectedTile = "Reports"),
                            ),
                          if (_can(Modules.settings, Perms.view))
                            SidebarTile(
                              title: "Settings",
                              icon: Icons.settings_rounded,
                              isSelected: selectedTile == "Settings",
                              onTap:
                                  () =>
                                      setState(() => selectedTile = "Settings"),
                            ),
                          SidebarTile(
                            title: "Profile",
                            icon: Icons.person_rounded,
                            isSelected: selectedTile == "Profile",
                            onTap:
                                () => setState(() => selectedTile = "Profile"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  const Divider(color: Colors.white10, height: 1),

                  // Logout
                  SidebarLogoutTile(onTap: () => _showLogoutDialog(context)),
                ],
              ),
            ),
          ),

          // Main Screen
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildTopHeader(context),
                const Divider(color: Color(0xFFE2E8F0), height: 1),

                // Main Page Body
                Expanded(child: getSelectedPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/icon/logo.png',
              width: 32,
              height: 32,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.location_on,
                    color: Color(0xFFFFC107),
                    size: 32,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  children: const [
                    TextSpan(
                      text: "Naattu",
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: "Link",
                      style: TextStyle(color: Color(0xFFFFC107)),
                    ),
                  ],
                ),
              ),
              Text(
                "Admin Panel",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8), // Slate 400
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Hamburger Icon
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Color(0xFF475569), size: 20),
            ),
          ),

          const Spacer(),

          // Notifications Badge Icon
          TopBarBadgeIcon(
            icon: Icons.notifications_none_rounded,
            count: 5,
            onTap: () => setState(() => selectedTile = "Notifications"),
          ),
          const SizedBox(width: 20),

          // Message Badge Icon
          TopBarBadgeIcon(
            icon: Icons.chat_bubble_outline_rounded,
            count: 3,
            onTap: () {},
          ),
          const SizedBox(width: 24),

          // Vertical Divider
          Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 24),

          // User Profile Info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF0FDF4),
                child: Text(
                  (_session.fullName?.isNotEmpty == true)
                      ? _session.fullName![0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _session.fullName ?? 'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _session.roleDisplayName ?? 'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
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
      builder:
          (context) => Stack(
            children: [
              Positioned(
                top: 70,
                right: 180,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 320,
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 16,
                          color: Colors.black12,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Notifications",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "New",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        if (notifications.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "No new notifications",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children:
                                  notifications
                                      .map(
                                        (note) => Material(
                                          color: Colors.transparent,
                                          child: ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: note.color.withValues(
                                                  alpha: 0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                note.icon,
                                                color: note.color,
                                                size: 16,
                                              ),
                                            ),
                                            title: Text(
                                              note.message,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 4,
                                                ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              note.onTap();
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
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
      builder:
          (ctx) => AlertDialog(
            title: Text(
              "Logout",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to logout?",
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseAuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Loginpage()),
                      (route) => false,
                    );
                  }
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFFFFC107) // Yellow active tint
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? const Color(0xFF1E293B) // Dark text for yellow bg
                        : const Color(0xFF94A3B8), // Slate unselected
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8),
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
  final Widget? trailing;

  const SidebarExpansionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.isInitiallyExpanded = false,
    this.onTap,
    this.trailing,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.trailing != null) const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Column(children: widget.children),
            ),
        ],
      ),
    );
  }
}

class SidebarLogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const SidebarLogoutTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF475569), size: 24),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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
