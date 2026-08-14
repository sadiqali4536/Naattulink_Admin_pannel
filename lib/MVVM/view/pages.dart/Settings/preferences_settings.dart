import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class PreferencesSettingsPage extends StatefulWidget {
  const PreferencesSettingsPage({super.key});

  @override
  State<PreferencesSettingsPage> createState() =>
      _PreferencesSettingsPageState();
}

class _PreferencesSettingsPageState extends State<PreferencesSettingsPage> {
  final _session = RbacSession();

  bool _can(String action) {
    return _session.hasPermission(Modules.settings, action);
  }

  String selectedTab = "General";
  bool isLoading = true;

  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportPhoneController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  final TextEditingController _iosAppVersionController =
      TextEditingController();
  final TextEditingController _platformNameController = TextEditingController();
  final TextEditingController _platformTaglineController =
      TextEditingController();
  String _defaultLanguage = 'English';
  String _timezone = 'Asia/Kolkata (GMT +05:30)';
  String _lastUpdated = 'Never';

  String appVersion = 'Loading...';

  // Original states for tracking unsaved changes
  String _origSupportEmail = '';
  String _origSupportPhone = '';
  String _origLanguage = 'English';
  String _origTimezone = 'Asia/Kolkata (GMT +05:30)';
  String _origAppVersion = '';
  String _origIosAppVersion = '';

  bool maintenanceMode = false;
  final TextEditingController _maintenanceMessageController =
      TextEditingController();
  bool _origMaintenanceMode = false;
  String _origMaintenanceMessage = '';

  // Saving states
  bool _isSavingGeneral = false;
  bool _isSavingMaintenance = false;

  bool get hasGeneralChanges =>
      _supportEmailController.text != _origSupportEmail ||
      _supportPhoneController.text != _origSupportPhone ||
      _defaultLanguage != _origLanguage ||
      _timezone != _origTimezone ||
      _appVersionController.text != _origAppVersion ||
      _iosAppVersionController.text != _origIosAppVersion;

  final List<String> tabs = ["General"];

  @override
  void initState() {
    super.initState();
    _appVersionController.addListener(() => setState(() {}));
    _iosAppVersionController.addListener(() => setState(() {}));
    _supportEmailController.addListener(() => setState(() {}));
    _supportPhoneController.addListener(() => setState(() {}));
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('platform_settings')
              .doc('general')
              .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _origSupportEmail = data['supportEmail'] ?? 'support@naattulink.com';
        _origSupportPhone = data['supportPhone'] ?? '+91 98765 43210';
        _origAppVersion = data['appVersion'] ?? '1.0.0';
        _origIosAppVersion = data['iosAppVersion'] ?? '1.0.0';
        _origLanguage = data['defaultLanguage'] ?? 'English';
        _origTimezone = data['timezone'] ?? 'Asia/Kolkata (GMT +05:30)';

        _platformNameController.text = data['platformName'] ?? 'NaattuLink';
        _platformTaglineController.text =
            data['platformTagline'] ?? 'Your City, One App';
      } else {
        _origSupportEmail = 'support@naattulink.com';
        _origSupportPhone = '+91 98765 43210';
        _origAppVersion = '1.0.0';
        _origIosAppVersion = '1.0.0';
        _origLanguage = 'English';
        _origTimezone = 'Asia/Kolkata (GMT +05:30)';

        _platformNameController.text = 'NaattuLink';
        _platformTaglineController.text = 'Your City, One App';
        _lastUpdated = 'Never';
      }

      _supportEmailController.text = _origSupportEmail;
      _supportPhoneController.text = _origSupportPhone;
      _appVersionController.text = _origAppVersion;
      _iosAppVersionController.text = _origIosAppVersion;
      _defaultLanguage = _origLanguage;
      _timezone = _origTimezone;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _platformNameController.dispose();
    _platformTaglineController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _appVersionController.dispose();
    _iosAppVersionController.dispose();
    _maintenanceMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFFFFC107)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 1000;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildTabs(),
                      const SizedBox(height: 24),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 17, child: _buildLeftColumn()),
                            const SizedBox(width: 24),
                            Expanded(flex: 10, child: _buildRightColumn()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildLeftColumn(),
                            const SizedBox(height: 24),
                            _buildRightColumn(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveGeneralSettings() async {
    setState(() => _isSavingGeneral = true);
    try {
      await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .set({
            'supportEmail': _supportEmailController.text,
            'supportPhone': _supportPhoneController.text,
            'defaultLanguage': _defaultLanguage,
            'timezone': _timezone,
            'appVersion': _appVersionController.text,
            'iosAppVersion': _iosAppVersionController.text,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _origSupportEmail = _supportEmailController.text;
          _origSupportPhone = _supportPhoneController.text;
          _origLanguage = _defaultLanguage;
          _origTimezone = _timezone;
          _origAppVersion = _appVersionController.text;
          _origIosAppVersion = _iosAppVersionController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('General settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving general settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingGeneral = false);
    }
  }

  Future<void> _saveMaintenance() async {
    setState(() => _isSavingMaintenance = true);
    try {
      await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .set({
            'maintenanceMode': maintenanceMode,
            'maintenanceMessage': _maintenanceMessageController.text,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _origMaintenanceMode = maintenanceMode;
          _origMaintenanceMessage = _maintenanceMessageController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site maintenance saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving site maintenance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingMaintenance = false);
    }
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your platform preferences and configurations',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              tabs.map((tab) {
                bool isSelected = selectedTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => selectedTab = tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFFFFC107)
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color:
                            isSelected
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(children: [_buildGeneralInfoCard()]);
  }

  Widget _buildRightColumn() {
    return Column(children: [_buildPlatformStatusCard()]);
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color iconBgColor,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: readOnly,
            fillColor: readOnly ? const Color(0xFFF8F9FA) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF4F46E5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyContainer(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items, {
    void Function(String?)? onChanged,
    bool disabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: disabled,
            fillColor: disabled ? const Color(0xFFF8F9FA) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF4F46E5),
                width: 1.5,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: disabled ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF64748B),
          ),
          dropdownColor: Colors.white,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: disabled ? null : (onChanged ?? (_) {}),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'General Information',
            'Update your platform basic information.',
            Icons.computer,
            const Color(0xFFFFF8E1), // Light amber background
            const Color(0xFF1E293B), // Dark slate icon for contrast
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyContainer('Platform Name', 'NaattuLink'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyContainer(
                  'Platform Tagline',
                  'Your City, One App',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Support Email',
                  _supportEmailController,
                  readOnly: !_can('edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Support Phone',
                  _supportPhoneController,
                  readOnly: !_can('edit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown('Default Language', 'English', [
                  'English',
                  'Malayalam',
                  'Hindi',
                ], disabled: !_can('edit')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown('Timezone', 'Asia/Kolkata (GMT +05:30)', [
                  'Asia/Kolkata (GMT +05:30)',
                  'UTC',
                ], disabled: !_can('edit')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Android App Version',
                  _appVersionController,
                  readOnly: !_can('edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'iOS App Version',
                  _iosAppVersionController,
                  readOnly: !_can('edit'),
                ),
              ),
            ],
          ),
          if (_can('edit') && hasGeneralChanges) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSavingGeneral ? null : _saveGeneralSettings,
                icon:
                    _isSavingGeneral
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(
                          Icons.save_outlined,
                          color: Colors.black,
                          size: 18,
                        ),
                label: Text(
                  _isSavingGeneral ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformStatusCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Platform Status',
            'Monitor the current status of the system.',
            Icons.speed_outlined,
            const Color(0xFFFFF8E1), // Light amber background
            const Color(0xFF1E293B), // Dark slate icon for contrast
          ),
          const SizedBox(height: 24),
          _buildStatusRowText('Support Email', _origSupportEmail),
          const SizedBox(height: 16),
          _buildStatusRowText('Support Phone', _origSupportPhone),
          const SizedBox(height: 16),
          _buildStatusRowText('Android Version', _origAppVersion),
          const SizedBox(height: 16),
          _buildStatusRowText('iOS Version', _origIosAppVersion),
        ],
      ),
    );
  }

  Widget _buildStatusRowText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, bool isPositive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRowWithDot(String label, String status, Color dotColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2024 NaattuLink. All rights reserved.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Row(
            children: const [
              Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              SizedBox(width: 16),
              Text('•', style: TextStyle(fontSize: 13, color: Colors.grey)),
              SizedBox(width: 16),
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              SizedBox(width: 16),
              Text('•', style: TextStyle(fontSize: 13, color: Colors.grey)),
              SizedBox(width: 16),
              Text(
                'Help Center',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
