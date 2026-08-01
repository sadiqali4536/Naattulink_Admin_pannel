import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/desktop_scaffold.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/mobile_scaffold.dart';
import 'package:swiftclean_admin/MVVM/Responsive/responsive_layput.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/tablet_scaffold.dart';
import 'package:swiftclean_admin/MVVM/view/loginpage.dart';
import 'package:swiftclean_admin/firebase_options.dart';
import 'package:swiftclean_admin/MVVM/utils/developer_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ensure the Super Admin account exists in Firebase Auth and Firestore
  await ensureSuperAdminAccountCreated();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFFFFC107),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC107),
          primary: const Color(0xFFFFC107),
        ),
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: const Color.fromARGB(
            255,
            253,
            251,
            243,
          ), // Very light soft yellow
          disabledColor: Colors.grey.shade200,
          labelStyle: const TextStyle(color: Colors.black87),
          secondaryLabelStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black12, width: 1),
          ),
          showCheckmark: false,
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const ResponsiveLayout(
              mobileScaffold: MobileScaffold(),
              tabletScaffold: TabletScaffold(),
              desktopScaffold: DesktopScaffold(),
            );
          } else {
            return const Loginpage();
          }
        },
      ),

      //   ResponsiveLayout(
      //   mobileScaffold: MobileScaffold(),
      //   tabletScaffold: TabletScaffold(),
      //   desktopScaffold: DesktopScaffold(),
      //  ),
      // ProfileWorker()
    );
  }
}
