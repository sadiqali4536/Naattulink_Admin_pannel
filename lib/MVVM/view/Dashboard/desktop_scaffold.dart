import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';
import 'package:swiftclean_admin/MVVM/utils/expansion_tile.dart';
import 'package:swiftclean_admin/MVVM/utils/notification_badge.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Ads%20Promotion/Ads%20Promotion.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Dashboard/Dashboard.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Loyalty%20Points/Loyalty%20Points.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Notifications/Notifications.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Payments/Payments.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Services.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';
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

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  String selectedTile = "Dashboard";
  String? expandedTile;
  final List<String> _suggestion = ["1", "2", "3"];
  List<NotificationItem> notifications = [];

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
      case "User Profile":
        return const ProfileUser();
      case "Services":
        return const Services();
      case "Payments":
        return  PaymentPage();
      case "Bookings":
        return  const Bookings();
      case "Loyalty Points":
        return const Loyaltypoints();
      case "Notifications":
        return const Notifications();
      case "Ads Promotion":
        return const Adspromotion();
      default:
        return Center(child: Text("Selected: $selectedTile"));
    }
  }

  void onTileExpandToggle(String titleTile) {
    setState(() {
      expandedTile = expandedTile == titleTile ? null : titleTile;
    });
  }

  void onItemSelected(String subItem) {
    setState(() {
      selectedTile = subItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myDefultBackround,
      body: Row(
        children: [
          Container(
            width: 300,
            height: double.infinity,
            color: AppColors.drawer,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset("assets/icon/logo.png", scale: 3, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/icon/SWIFT.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)),
                        const SizedBox(width: 5),
                        Image.asset("assets/icon/CLEAN.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)),
                      ],
                    ),
                    const SizedBox(height: 50),
                    buildDrawerTile("Dashboard", "assets/icon/dashboard.png"),
                    CustomExpansionTile(
                      title: "Workers",
                       MainIcon: Image.asset("assets/icon/worker.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.people)),
                      subItems: [
                        SubItem(title: "Worker Profile", icon: const Icon(Icons.person)),
                        SubItem(title: "Verification", icon: const Icon(Icons.verified)),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Users",
                      MainIcon: const Icon(Icons.person),
                      subItems: [
                        SubItem(title: "User Profile", icon: const Icon(Icons.person)),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Manage Services",
                       MainIcon: Image.asset("assets/icon/services.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.home_repair_service)),
                      subItems: [
                        SubItem(title: "Services", icon: Image.asset("assets/icon/services.png")),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Billing & Payments",
                       MainIcon: Image.asset("assets/icon/payment.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment)),
                      subItems: [
                         SubItem(title: "Payments", icon: Image.asset("assets/icon/payment.png")),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Manage Bookings",
                       MainIcon: Image.asset("assets/icon/bookings.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.book_online)),
                      subItems: [
                        SubItem(title: "Bookings", icon: Image.asset("assets/icon/bookings.png")),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Rewards Management",
                       MainIcon: Image.asset("assets/icon/Loyalty_Point.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.star)),
                      subItems: [
                        SubItem(title: "Loyalty Points", icon: Image.asset("assets/icon/Loyalty_Point.png")),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Notifications",
                       MainIcon: Image.asset("assets/icon/notification.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.notifications)),
                      subItems: [
                        SubItem(title: "Notifications", icon: Image.asset("assets/icon/notification.png")),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                    CustomExpansionTile(
                      title: "Ad Center",
                       MainIcon: Image.asset("assets/icon/ads_promotion.png", scale: 2, errorBuilder: (context, error, stackTrace) => const Icon(Icons.campaign)),
                      subItems: [
                        SubItem(title: "Ads Promotion", icon: Image.asset("assets/icon/ads_promotion.png")),
                      ],
                      expandedTile: expandedTile,
                      selectedTile: selectedTile,
                      onTileExpandToggle: onTileExpandToggle,
                      onItemSelected: onItemSelected,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Autocomplete<String>(
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              onFieldSubmitted: (value) {
                                focusNode.unfocus();
                                onFieldSubmitted();
                              },
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                hintText: "Search here",
                                hintStyle: const TextStyle(color: AppColors.textcolor1),
                                suffixIcon: const Icon(CupertinoIcons.search, color: AppColors.textcolor1),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(color: AppColors.black),
                            );
                          },
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _suggestion.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (selection) => debugPrint("Selected: $selection"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      NotificationBadge(
                        icon: Icons.notifications_none_rounded,
                        count: notifications.length,
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.transparent,
                            builder: (context) => Stack(
                              children: [
                                Positioned(
                                  top: 80,
                                  right: 30,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 300,
                                      constraints: const BoxConstraints(maxHeight: 400),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 4)),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 8),
                                          const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const Divider(height: 0),
                                          if (notifications.isEmpty)
                                            const Padding(
                                              padding: EdgeInsets.all(20),
                                              child: Text("No notifications"),
                                            )
                                          else
                                            SizedBox(
                                              height: 300,
                                              child: ListView(
                                                children: notifications.map((note) => ListTile(
                                                  leading: Icon(note.icon, color: note.color),
                                                  title: Text(note.message),
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
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(height: 60, width: 2, color: AppColors.border),
                      const SizedBox(width: 10),
                      Container(
                        height: 60,
                        width: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(colors: [AppColors.gradient1, AppColors.gradient2]),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 12),
                            Text("Hi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(width: 7),
                            Text("Admin Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(width: 20),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              maxRadius: 27,
                              child: Icon(Icons.person, color: AppColors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Expanded(child: SingleChildScrollView(child: getSelectedPage())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDrawerTile(String title, String assetPath) {
    return Container(
      color: selectedTile == title ? AppColors.gradient1 : Colors.transparent,
      child: ListTile(
        leading: Image.asset(
          assetPath,
          color: selectedTile == title ? Colors.white : AppColors.textcolor1,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selectedTile == title ? Colors.white : AppColors.textcolor1,
          ),
        ),
        selected: selectedTile == title,
        onTap: () => onItemSelected(title),
      ),
    );
  }
}


