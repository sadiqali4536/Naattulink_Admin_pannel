import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

/// Wraps a page/widget and checks RBAC permissions before rendering.
///
/// Usage:
/// ```dart
/// PermissionGuard(
///   module: Modules.reports,
///   action: Perms.view,
///   child: ReportsPage(),
/// )
/// ```
///
/// If the user lacks the required permission, an "Access Denied" screen is shown.
class PermissionGuard extends StatelessWidget {
  final String module;
  final String action;
  final Widget child;
  final Widget? customDeniedWidget;

  const PermissionGuard({
    super.key,
    required this.module,
    required this.action,
    required this.child,
    this.customDeniedWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (RbacSession().hasPermission(module, action)) {
      return child;
    }
    return customDeniedWidget ?? _AccessDeniedScreen(module: module, action: action);
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  final String module;
  final String action;

  const _AccessDeniedScreen({required this.module, required this.action});

  @override
  Widget build(BuildContext context) {
    final moduleName = module.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Access Denied',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have permission to access "$moduleName".',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Required: $moduleName › ${action[0].toUpperCase()}${action.substring(1)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    'Contact your Super Admin to request access.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
