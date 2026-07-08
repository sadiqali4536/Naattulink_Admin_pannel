import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/dashboard_card.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Dashboard Cards
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DashboardCard(
                    title: "Total Bookings",
                    value: "120",
                    color: Color.fromARGB(255, 251, 251, 252),
                    imagePath: 'assets/icon/dashboard_sheet.png',
                    icon: 'assets/icon/arow_down.png',
                    containercolor: Color.fromARGB(255, 255, 17, 0),
                    percentage: '4%',
                    subtitle: '(30days)',
                    subicon: Icons.arrow_upward,
                    subcontainercolor: Colors.black38,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: "Completed Bookings",
                    value: "45",
                    color: Color.fromARGB(255, 255, 255, 255),
                    imagePath: 'assets/icon/dashboard_sheet.png',
                    icon: 'assets/icon/tick.png',
                    containercolor: Color.fromRGBO(27, 242, 62, 1),
                    percentage: '4%',
                    subtitle: '(30days)',
                    subicon: Icons.arrow_upward,
                    subcontainercolor: Colors.black38,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: "Canceled Bookings",
                    value: "78",
                    color: Color.fromARGB(255, 250, 250, 250),
                    imagePath: 'assets/icon/dashboard_sheet.png',
                    icon: 'assets/icon/cross.png',
                    containercolor: Color.fromRGBO(255, 218, 218, 1),
                    percentage: '4%',
                    subtitle: '(30days)',
                    subicon: Icons.arrow_downward,
                    subcontainercolor: Colors.black38,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: "Total Revenue",
                    value: "30",
                    color: Color.fromARGB(255, 255, 255, 255),
                    imagePath: 'assets/icon/dashboard_sheet.png',
                    icon: 'assets/icon/money.png',
                    containercolor: Color.fromARGB(255, 255, 255, 255),
                    percentage: '5%',
                    subtitle: '(30days)',
                    subicon: Icons.arrow_downward,
                    subcontainercolor: Colors.black38,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
           
          ],
        ),
      ),
    );
  }
}
