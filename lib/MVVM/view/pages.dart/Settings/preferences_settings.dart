import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PreferencesSettingsPage extends StatefulWidget {
  const PreferencesSettingsPage({super.key});

  @override
  State<PreferencesSettingsPage> createState() =>
      _PreferencesSettingsPageState();
}

class _PreferencesSettingsPageState extends State<PreferencesSettingsPage> {
  String selectedTab = "General";
  bool maintenanceMode = false;
  bool isLoading = true;

  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportPhoneController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPhoneController = TextEditingController();
  final TextEditingController _officeAddressController =
      TextEditingController();
  final TextEditingController _maintenanceMessageController =
      TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  final TextEditingController _platformNameController = TextEditingController();
  final TextEditingController _platformTaglineController =
      TextEditingController();
  String _defaultLanguage = 'English';
  String _timezone = 'Asia/Kolkata (GMT +05:30)';
  String _lastUpdated = 'Never';

  String appVersion = 'Loading...';
  String _initialAppVersion = '1.0.0';

  final List<String> tabs = ["General"];

  @override
  void initState() {
    super.initState();
    _appVersionController.addListener(() {
      setState(() {});
    });
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
        _supportEmailController.text =
            data['supportEmail'] ?? 'support@naattulink.com';
        _supportPhoneController.text =
            data['supportPhone'] ?? '+91 98765 43210';
        _adminEmailController.text =
            data['adminEmail'] ?? 'admin@naattulink.com';
        _adminPhoneController.text = data['adminPhone'] ?? '+91 98765 12345';
        _officeAddressController.text =
            data['officeAddress'] ??
            'NaattuLink Admin Office, 2nd Floor, Kinfra Techno Park,\nKozhikode, Kerala, India - 673016';
        maintenanceMode = data['maintenanceMode'] ?? false;
        _maintenanceMessageController.text =
            data['maintenanceMessage'] ??
            'We are currently performing scheduled\nmaintenance. Please try again later.';
        _appVersionController.text = data['appVersion'] ?? '1.0.0';
        _initialAppVersion = _appVersionController.text;
      } else {
        _platformNameController.text = 'NaattuLink';
        _platformTaglineController.text = 'Your City, One App';
        _defaultLanguage = 'English';
        _timezone = 'Asia/Kolkata (GMT +05:30)';
        _lastUpdated = 'Never';
        _supportEmailController.text = 'support@naattulink.com';
        _supportPhoneController.text = '+91 98765 43210';
        _adminEmailController.text = 'admin@naattulink.com';
        _adminPhoneController.text = '+91 98765 12345';
        _officeAddressController.text =
            'NaattuLink Admin Office, 2nd Floor, Kinfra Techno Park,\nKozhikode, Kerala, India - 673016';
        maintenanceMode = false;
        _maintenanceMessageController.text =
            'We are currently performing scheduled\nmaintenance. Please try again later.';
        _appVersionController.text = '1.0.0';
        _initialAppVersion = '1.0.0';
      }
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
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _officeAddressController.dispose();
    _maintenanceMessageController.dispose();
    _appVersionController.dispose();
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

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .set({
            'platformName': _platformNameController.text,
            'platformTagline': _platformTaglineController.text,
            'defaultLanguage': _defaultLanguage,
            'timezone': _timezone,
            'lastUpdated': FieldValue.serverTimestamp(),
            'supportEmail': _supportEmailController.text,
            'supportPhone': _supportPhoneController.text,
            'adminEmail': _adminEmailController.text,
            'adminPhone': _adminPhoneController.text,
            'officeAddress': _officeAddressController.text,
            'maintenanceMode': maintenanceMode,
            'maintenanceMessage': _maintenanceMessageController.text,
            'appVersion': _appVersionController.text,
          }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage your platform preferences and configurations',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, color: Colors.black87, size: 20),
              label: const Text(
                'Discard Changes',
                style: TextStyle(color: Colors.black87),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(
                Icons.save_outlined,
                color: Color(0xFF1E293B),
                size: 20,
              ),
              label: const Text(
                'Save Changes',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107), // Theme yellow
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.black54,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
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
    return Column(
      children: [
        _buildGeneralInfoCard(),
        const SizedBox(height: 24),
        _buildAdminContactCard(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildSiteMaintenanceCard(),
        const SizedBox(height: 24),
        _buildPlatformStatusCard(),
        const SizedBox(height: 24),
        _buildDangerZoneCard(),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
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
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 13,
            color: readOnly ? Colors.black54 : Colors.black87,
          ),
          decoration: InputDecoration(
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade100 : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
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
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
          onChanged: (_) {},
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
            Colors.green.shade50,
            Colors.green,
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
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Support Phone',
                  _supportPhoneController,
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
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown('Timezone', 'Asia/Kolkata (GMT +05:30)', [
                  'Asia/Kolkata (GMT +05:30)',
                  'UTC',
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Required Client App Version',
                  _appVersionController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                    _appVersionController.text != _initialAppVersion
                        ? Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final newVersion =
                                  _appVersionController.text.trim();
                              if (newVersion.isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid App Version',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              try {
                                await FirebaseFirestore.instance
                                    .collection('platform_settings')
                                    .doc('general')
                                    .set({
                                      'appVersion': newVersion,
                                    }, SetOptions(merge: true));
                                setState(() {
                                  _initialAppVersion = newVersion;
                                  _appVersionController.text =
                                      newVersion; // ensures trimmed text is set
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'App version updated successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Save Version'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        )
                        : const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContactCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Admin Contact Details',
            'These details will be used for important communications.',
            Icons.person_outline,
            Colors.blue.shade50,
            Colors.blue,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Admin Email', _adminEmailController),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Admin Phone', _adminPhoneController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Office Address',
            _officeAddressController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSiteMaintenanceCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Site Maintenance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enable maintenance mode to restrict\naccess to the platform.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'When enabled, only admins can access\nthe platform.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: maintenanceMode,
                onChanged: (val) => setState(() => maintenanceMode = val),
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Maintenance Message',
            _maintenanceMessageController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStatusCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          _buildStatusRow(
            'Current Status',
            maintenanceMode ? 'Maintenance' : 'Online',
            !maintenanceMode,
          ),
          const SizedBox(height: 16),
          _buildStatusRowText('Last Updated', _lastUpdated),
          const SizedBox(height: 16),
          _buildStatusRowText('Version', appVersion),

          const SizedBox(height: 16),
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

  Widget _buildDangerZoneCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This action will reset all settings to default values.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            label: const Text(
              'Reset All Settings',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
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
