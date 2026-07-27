import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/Responsive/responsive_layput.dart';
import 'package:swiftclean_admin/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/desktop_scaffold.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/mobile_scaffold.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/tablet_scaffold.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _buildDesktopUI(constraints.maxWidth, constraints.maxHeight);
        }
        return _buildMobileUI(constraints.maxWidth, constraints.maxHeight);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop Layout
  // ---------------------------------------------------------------------------
  Widget _buildDesktopUI(double w, double h) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Right panel — form
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: w * 0.5,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 40,
                  ),
                  child: _buildLoginForm(desktop: true),
                ),
              ),
            ),
          ),
          // Left panel — branding (Yellow backdrop)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: (w * 0.5) + 60,
            child: ClipPath(
              clipper: const LoginCurveClipper(),
              child: Container(color: const Color(0xFFFFC107)),
            ),
          ),
          // Left panel — branding (Dark Blue foreground)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: (w * 0.5) + 40,
            child: ClipPath(
              clipper: const LoginCurveClipper(),
              child: Container(
                color: const Color(0xFF0A192F),
                child: Center(
                  child: SingleChildScrollView(child: _buildBrandPanel(w, h)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile Layout
  // ---------------------------------------------------------------------------
  Widget _buildMobileUI(double w, double h) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top brand area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: _buildBrandPanel(w, h, isMobile: true),
              ),
              // Card form
              Container(
                constraints: const BoxConstraints(minHeight: 500),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(28),
                child: _buildLoginForm(desktop: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Brand panel (left desktop / top mobile)
  // ---------------------------------------------------------------------------
  Widget _buildBrandPanel(double w, double h, {bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/icon/logo.png',
            width: isMobile ? 100 : 140,
            height: isMobile ? 100 : 140,
            errorBuilder:
                (context, error, stackTrace) => Icon(
                  Icons.location_on,
                  color: const Color(0xFFFFC107),
                  size: isMobile ? 100 : 140,
                ),
          ),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: isMobile ? 32 : 42,
                fontWeight: FontWeight.bold,
              ),
              children: const [
                TextSpan(text: "Naattu", style: TextStyle(color: Colors.white)),
                TextSpan(
                  text: "Link",
                  style: TextStyle(color: Color(0xFFFFC107)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting Communities, Empowering Locals',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: const Color(0xFFFFC107),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),

          // Divider Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 2, width: 40, color: const Color(0xFFFFC107)),
              const SizedBox(width: 16),
              Text(
                'Admin Panel',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFC107),
                ),
              ),
              const SizedBox(width: 16),
              Container(height: 2, width: 40, color: const Color(0xFFFFC107)),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Login Form
  // ---------------------------------------------------------------------------
  Widget _buildLoginForm({required bool desktop}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome Back',
            style: GoogleFonts.inter(
              fontSize: desktop ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your admin account',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 36),

          // Username field
          _buildFieldLabel('Username'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.text,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Please enter your username'
                        : null,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: 'Enter your username',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // Password field
          _buildFieldLabel('Web Panel Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            validator:
                (v) =>
                    (v == null || v.isEmpty)
                        ? 'Please enter your password'
                        : null,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: 'Enter your web panel password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remember Me and Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: true, // Dummy value for UI
                      onChanged: (v) {},
                      activeColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB), // Blue color from mockup
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107), // Yellow
                foregroundColor: const Color(0xFF1E293B), // Dark blue text
                elevation: 0,
                disabledBackgroundColor: const Color(
                  0xFFFFC107,
                ).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 11),
                children: const [
                  TextSpan(
                    text: 'NaattuLink ',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Admin Panel • Secure Login',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFFCBD5E1),
      ),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService.instance.signInWithUsername(
        _usernameController.text.trim(),
        _passController.text,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (_) => const ResponsiveLayout(
                mobileScaffold: MobileScaffold(),
                tabletScaffold: TabletScaffold(),
                desktopScaffold: DesktopScaffold(),
              ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this username.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect web panel password. '
            'Use the password provided by your administrator.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class LoginCurveClipper extends CustomClipper<Path> {
  const LoginCurveClipper();

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width - 120, 0);
    path.quadraticBezierTo(
      size.width,
      size.height * 0.25,
      size.width - 60,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width - 120,
      size.height * 0.75,
      size.width,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
