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
import 'package:swiftclean_admin/MVVM/view/pages.dart/Taxi Drivers/taxi_drivers.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Truck and JCB/truck_and_jcb.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Healthcare/healthcare.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Businesses/businesses.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bus Routes/bus_routes.dart';
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
import 'package:swiftclean_admin/MVVM/view/pages.dart/Settings/preferences_settings.dart';
import 'package:swiftclean_admin/MVVM/view/loginpage.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Reports/reports_overview.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Recent Activity/recent_activity.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Online Store/store_products.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Online Store/store_orders.dart';

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

class TabletScaffold extends StatefulWidget {
  const TabletScaffold({super.key});

  @override
  State<TabletScaffold> createState() => _TabletScaffoldState();
}

class _TabletScaffoldState extends State<TabletScaffold> {
  String selectedTile = "Dashboard";
  List<NotificationItem> notifications = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _session = RbacSession();
  int pendingBookingsCount = 0;
  int ongoingBookingsCount = 0;
  int pendingWorkersCount = 0;
  bool _sessionLoaded = false;
  bool _loggedSidebar = false;

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
    if (!_session.isActive) await _session.loadSession();
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
    print(
      '[SIDEBAR] Store Products -> ${_can(Modules.storeProducts, Perms.view) ? "Visible" : "Hidden (Missing store_products.view)"}',
    );
    print(
      '[SIDEBAR] Store Orders -> ${_can(Modules.storeOrders, Perms.view) ? "Visible" : "Hidden (Missing store_orders.view)"}',
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
    if (_can(Modules.storeProducts, Perms.view)) return "Store Products";
    if (_can(Modules.storeOrders, Perms.view)) return "Store Orders";
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
                  (doc.data()['work_status'] ?? 'pending')
                      .toString()
                      .trim()
                      .toLowerCase();
              final completedStatus =
                  (doc.data()['completed_status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
              if (bookingStatus == 'confirmed' && workStatus == 'pending' && completedStatus != 'ongoing') {
                pCount++;
              }
              if (completedStatus == 'ongoing') {
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
          child: Dashboard(
            onNavigate: (tab) => setState(() => selectedTile = tab),
          ),
        );
      case "Recent Activity":
        return PermissionGuard(
          module: Modules.dashboard,
          action: Perms.view,
          child: RecentActivityPage(
            onNavigate: (tab) => setState(() => selectedTile = tab),
          ),
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
      case "Profile":
        return const AdminProfilePage();
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
      case "Bus Routes":
        return PermissionGuard(
          module: Modules.bus,
          action: Perms.view,
          child: const BusRoutesPage(),
        );
      case "Reports":
        return PermissionGuard(
          module: Modules.reports,
          action: Perms.view,
          child: const ReportsOverviewPage(),
        );
      case "Store Products":
        return PermissionGuard(
          module: Modules.storeProducts,
          action: Perms.view,
          child: const StoreProductsPage(),
        );
      case "Store Orders":
        return PermissionGuard(
          module: Modules.storeOrders,
          action: Perms.view,
          child: const StoreOrdersPage(),
        );
      default:
        return Center(
          child: Text(
            "Selected: $selectedTile",
            style: GoogleFonts.inter(
              fontSize: 16,
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
          Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
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
              fontSize: 13,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          TopBarBadgeIcon(
            icon: Icons.notifications_none_rounded,
            count: 5,
            onTap: () => setState(() => selectedTile = "Notifications"),
          ),
          const SizedBox(width: 12),
          TopBarBadgeIcon(
            icon: Icons.chat_bubble_outline_rounded,
            count: 3,
            onTap: () {},
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://randomuser.me/api/portraits/men/32.jpg',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
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
                    if (_can(Modules.dashboard, Perms.view))
                      SidebarTile(
                        title: "Dashboard",
                        icon: Icons.dashboard_rounded,
                        isSelected: selectedTile == "Dashboard",
                        onTap: () {
                          setState(() => selectedTile = "Dashboard");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.userManagement, Perms.view) ||
                        _can(Modules.roles, Perms.view) ||
                        _can(Modules.userManagement, 'assign_role') ||
                        _can(Modules.grantAccess, Perms.view))
                      SidebarExpansionTile(
                        title: "User Management",
                        icon: Icons.people_alt_rounded,
                        isInitiallyExpanded:
                            selectedTile == "User Profile" ||
                            selectedTile == "User Roles" ||
                            selectedTile == "Banned Users" ||
                            selectedTile == "Suspended Users",
                        onTap:
                            () => setState(() => selectedTile = "User Profile"),
                        children: [
                          if (_can(Modules.userManagement, Perms.view))
                            SidebarTile(
                              title: "Users",
                              icon: Icons.person_outline_rounded,
                              isSelected: selectedTile == "User Profile",
                              onTap: () {
                                setState(() => selectedTile = "User Profile");
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.roles, Perms.view) ||
                              _can(Modules.userManagement, 'assign_role'))
                            SidebarTile(
                              title: "User Roles",
                              icon: Icons.shield_outlined,
                              isSelected: selectedTile == "User Roles",
                              onTap: () {
                                setState(() => selectedTile = "User Roles");
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.userManagement, 'ban_user'))
                            SidebarTile(
                              title: "Banned Users",
                              icon: Icons.block_flipped,
                              isSelected: selectedTile == "Banned Users",
                              onTap: () {
                                setState(() => selectedTile = "Banned Users");
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.userManagement, 'suspend_user'))
                            SidebarTile(
                              title: "Suspended Users",
                              icon: Icons.pause_circle_outline,
                              isSelected: selectedTile == "Suspended Users",
                              onTap: () {
                                setState(
                                  () => selectedTile = "Suspended Users",
                                );
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                        ],
                      ),
                    if (_can(Modules.workerManagement, Perms.view) ||
                        _can(Modules.workerManagement, 'approve_worker') ||
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
                            if (count == 0) return const SizedBox.shrink();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                borderRadius: BorderRadius.circular(10),
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
                        onTap:
                            () => setState(() => selectedTile = "All Workers"),
                        children: [
                          if (_can(Modules.workerManagement, Perms.view))
                            SidebarTile(
                              title: "All Workers",
                              icon: Icons.group_outlined,
                              isSelected: selectedTile == "All Workers",
                              onTap: () {
                                setState(() => selectedTile = "All Workers");
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.workerManagement, 'approve_worker'))
                            SidebarTile(
                              title: "Pending Approvals",
                              icon: Icons.hourglass_empty_rounded,
                              isSelected: selectedTile == "Pending Approvals",
                              onTap: () {
                                setState(
                                  () => selectedTile = "Pending Approvals",
                                );
                                _scaffoldKey.currentState?.closeDrawer();
                              },
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
                                      borderRadius: BorderRadius.circular(10),
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
                          if (_can(Modules.workerManagement, 'approve_worker'))
                            SidebarTile(
                              title: "Approved Workers",
                              icon: Icons.check_circle_outline_rounded,
                              isSelected: selectedTile == "Approved Workers",
                              onTap: () {
                                setState(
                                  () => selectedTile = "Approved Workers",
                                );
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.workerManagement, 'reject_worker'))
                            SidebarTile(
                              title: "Rejected Workers",
                              icon: Icons.cancel_outlined,
                              isSelected: selectedTile == "Rejected Workers",
                              onTap: () {
                                setState(
                                  () => selectedTile = "Rejected Workers",
                                );
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.workerManagement, 'suspend_worker'))
                            SidebarTile(
                              title: "Suspended Workers",
                              icon: Icons.pause_circle_outline_rounded,
                              isSelected: selectedTile == "Suspended Workers",
                              onTap: () {
                                setState(
                                  () => selectedTile = "Suspended Workers",
                                );
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                        ],
                      ),
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
                                    color: const Color(0xFFF59E0B),
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
                                )
                                : null,
                        onTap:
                            () => setState(() => selectedTile = "All Bookings"),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
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
                            onTap: () {
                              setState(() => selectedTile = "On Going Works");
                              _scaffoldKey.currentState?.closeDrawer();
                            },
                            trailing:
                                ongoingBookingsCount > 0
                                    ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6),
                                        borderRadius: BorderRadius.circular(10),
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
                            isSelected: selectedTile == "Completed Bookings",
                            onTap: () {
                              setState(
                                () => selectedTile = "Completed Bookings",
                              );
                              _scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                          SidebarTile(
                            title: "Cancelled Bookings",
                            icon: Icons.cancel_outlined,
                            isSelected: selectedTile == "Cancelled Bookings",
                            onTap: () {
                              setState(
                                () => selectedTile = "Cancelled Bookings",
                              );
                              _scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                        ],
                      ),
                    if (_can(Modules.services, Perms.view))
                      SidebarExpansionTile(
                        title: "Services",
                        icon: Icons.home_repair_service_rounded,
                        isInitiallyExpanded:
                            selectedTile == "All Services" ||
                            selectedTile == "Categories" ||
                            selectedTile == "Service Reviews",
                        onTap:
                            () => setState(() => selectedTile = "All Services"),
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
                    if (_can(Modules.storeProducts, Perms.view) || _can(Modules.storeOrders, Perms.view))
                      SidebarExpansionTile(
                        title: "Online Store",
                        icon: Icons.storefront_rounded,
                        isInitiallyExpanded:
                            selectedTile == "Store Products" ||
                            selectedTile == "Store Orders",
                        onTap: () => setState(() =>
                            selectedTile = _can(Modules.storeProducts, Perms.view)
                                ? "Store Products"
                                : "Store Orders"),
                        children: [
                          if (_can(Modules.storeProducts, Perms.view))
                            SidebarTile(
                              title: "Store Products",
                              icon: Icons.inventory_2_rounded,
                              isSelected: selectedTile == "Store Products",
                              onTap: () {
                                setState(() => selectedTile = "Store Products");
                                _scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          if (_can(Modules.storeOrders, Perms.view))
                            SidebarTile(
                              title: "Store Orders",
                              icon: Icons.shopping_cart_checkout_rounded,
                              isSelected: selectedTile == "Store Orders",
                              onTap: () {
                                setState(() => selectedTile = "Store Orders");
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
                    if (_can(Modules.advertisement, Perms.view))
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
                    if (_can(Modules.bus, Perms.view))
                      SidebarTile(
                        title: "Bus Routes",
                        icon: Icons.directions_bus_rounded,
                        isSelected: selectedTile == "Bus Routes",
                        onTap: () {
                          setState(() => selectedTile = "Bus Routes");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.taxi, Perms.view))
                      SidebarTile(
                        title: "Taxi Drivers",
                        icon: Icons.local_taxi_rounded,
                        isSelected: selectedTile == "Taxi Drivers",
                        onTap: () {
                          setState(() => selectedTile = "Taxi Drivers");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.truck, Perms.view))
                      SidebarTile(
                        title: "Truck & JCB",
                        icon: Icons.fire_truck_rounded,
                        isSelected: selectedTile == "Truck & JCB",
                        onTap: () {
                          setState(() => selectedTile = "Truck & JCB");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.healthcare, Perms.view))
                      SidebarTile(
                        title: "Healthcare",
                        icon: Icons.local_hospital_rounded,
                        isSelected: selectedTile == "Healthcare",
                        onTap: () {
                          setState(() => selectedTile = "Healthcare");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.business, Perms.view))
                      SidebarTile(
                        title: "Businesses",
                        icon: Icons.store_rounded,
                        isSelected: selectedTile == "Businesses",
                        onTap: () {
                          setState(() => selectedTile = "Businesses");
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
                    if (_can(Modules.notifications, Perms.view))
                      SidebarTile(
                        title: "Notifications",
                        icon: Icons.notifications_rounded,
                        isSelected: selectedTile == "Notifications",
                        onTap: () {
                          setState(() => selectedTile = "Notifications");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.reports, Perms.view))
                      SidebarTile(
                        title: "Reports",
                        icon: Icons.bar_chart_rounded,
                        isSelected: selectedTile == "Reports",
                        onTap: () {
                          setState(() => selectedTile = "Reports");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    if (_can(Modules.settings, Perms.view))
                      SidebarTile(
                        title: "Settings",
                        icon: Icons.settings_rounded,
                        isSelected: selectedTile == "Settings",
                        onTap: () {
                          setState(() => selectedTile = "Settings");
                          _scaffoldKey.currentState?.closeDrawer();
                        },
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
                    fontSize: 16,
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
      builder:
          (context) => Stack(
            children: [
              Positioned(
                top: 70,
                right: 100,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 300,
                    constraints: const BoxConstraints(maxHeight: 385),
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
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Notifications",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                            padding: const EdgeInsets.all(18.0),
                            child: Text(
                              "No new notifications",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
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
                                                size: 14,
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
                                                  horizontal: 14,
                                                  vertical: 3,
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
          (context) => AlertDialog(
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
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
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
            color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF94A3B8), size: 18),
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
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.trailing != null) const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
            Icon(icon, color: const Color(0xFF475569), size: 22),
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
