import 'dart:core';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget mobileScaffold;
  final Widget tabletScaffold;
  final Widget desktopScaffold;

  const ResponsiveLayout({
    super.key,
    required this.mobileScaffold,
    required this.tabletScaffold,
    required this.desktopScaffold,
  });

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  late Future<void> _loadSessionFuture;

  @override
  void initState() {
    super.initState();
    _loadSessionFuture = RbacSession().loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return widget.mobileScaffold;
            } else if (constraints.maxWidth < 1100) {
              return widget.tabletScaffold;
            } else {
              return widget.desktopScaffold;
            }
          },
        );
      },
    );
  }
}
