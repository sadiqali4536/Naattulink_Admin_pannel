import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String percentage;
  final String subtitle;
  final String value;
  final Color color;
  final String? imagePath;
  final String? icon;
  final Color containercolor;
  final Color subcontainercolor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.imagePath,
    this.icon,
    required this.containercolor,
    required this.percentage,
    required this.subtitle,
    required this.subcontainercolor, required IconData subicon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 125,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Stack(
              children: [
                // Title
                Positioned(
                  top: 42,
                  left: 96,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(133, 130, 130, 1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Subtitle
                Positioned(
                  top: 65,
                  left: 138,
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(163, 163, 163, 1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Percentage
                Positioned(
                  top: 65,
                  left: 115,
                  child: Text(
                    percentage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(163, 163, 163, 1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Main image
                if (imagePath != null)
                  Positioned(
                    top: 13,
                    left: 15,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 176, 116, 0.15),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Center(
                        child: Image.asset(
                          imagePath!,
                          height: 35,
                          width: 35,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                // Small icon
                if (icon != null)
                  Positioned(
                    top: 31,
                    left: 55,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: containercolor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Image.asset(
                        icon!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // Conditional trend icon (up/down)
                Positioned(
                  top: 68,
                  left: 97,
                  child: Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      color: percentage.contains('-') ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      percentage.contains('-') ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Value (count)
                Positioned(
                  bottom: 43,
                  left: 110,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
