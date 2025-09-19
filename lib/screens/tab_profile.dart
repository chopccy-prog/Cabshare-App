// lib/screens/tab_profile.dart - ALIGNED WITH NEW APP THEME (CONTINUED)
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'login_page.dart';
import 'wallet_screen.dart';
import 'profile_edit_screen.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({super.key, required this.api});
  final ApiClient api;

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late final TabController _tabs;

  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _kyc = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    
    setState(() => _loading = true);
    try {
      // Load profile data using the API client
      final profileResponse = await widget.api.getProfile();
      _profile = profileResponse;

      // Load vehicles
      try {
        final vehiclesResponse = await widget.api.getVehicles();
        _vehicles = vehiclesResponse;
      } catch (e) {
        print('Error loading vehicles: $e');
        _vehicles = [];
      }

      // Load KYC documents
      try {
        final kycResponse = await widget.api.getKycDocuments();
        _kyc = kycResponse;
      } catch (e) {
        print('Error loading KYC: $e');
        _kyc = [];
      }

    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginPage(api: widget.api),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: AppTheme.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'About you'),
            Tab(text: 'Account'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spaceLG),
                  Text('Loading profile...', style: AppTheme.bodyMedium),
                ],
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _buildAboutYouTab(),
                _buildAccountTab(),
              ],
            ),
    );
  }

  Widget _buildAboutYouTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeaderCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildProfileProgressCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildVerificationCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildTravelPreferencesCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildVehiclesSection(),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWalletSection(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildSecurityCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildNotificationsCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildPrivacyCard(),
          const SizedBox(height: AppTheme.spaceXL),
          _buildHelpCard(),
          const SizedBox(height: AppTheme.space4XL),
          Center(
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusError,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: AppTheme.spaceMD),
                  Text('Logout', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final name = _profile?['full_name'] ?? 'Demo User';
    final memberSince = _profile?['created_at'] != null 
        ? DateTime.parse(_profile!['created_at']).year.toString()
        : DateTime.now().year.toString();

    return Container(
      decoration: AppTheme.cardDecoration(elevation: 2),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_isProfileVerified())
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.statusSuccess,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToEditProfile(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTheme.headingSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Member since $memberSince',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Row(
                  children: [
                    _buildStatItem(Icons.directions_car, '0', 'rides'),
                    const SizedBox(width: AppTheme.spaceXL),
                    _buildStatItem(Icons.star, '0.0', 'rating'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: AppTheme.spaceXS),
        Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: AppTheme.spaceXS),
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildProfileProgressCard() {
    final progressItems = [
      {'title': 'Add phone number', 'completed': _profile?['phone'] != null},
      {'title': 'Verify email', 'completed': _profile?['email_verified'] == true},
      {'title': 'Add vehicle', 'completed': _vehicles.isNotEmpty},
      {'title': 'Add travel preferences', 'completed': _profile?['bio'] != null},
      {'title': 'Verify ID document', 'completed': _hasVerifiedDocument()},
    ];

    final completedCount = progressItems.where((item) => item['completed'] == true).length;
    final progressPercentage = (completedCount / progressItems.length * 100).round();

    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1).copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            AppTheme.primaryBlue.withOpacity(0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Complete your profile', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spaceMD),
          const Text(
            'This helps build trust, encouraging members to travel with you.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: AppTheme.textMuted.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Text(
                '$completedCount of ${progressItems.length} complete',
                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          if (completedCount < progressItems.length)
            ...progressItems
                .where((item) => item['completed'] == false)
                .take(1)
                .map((item) => InkWell(
                      onTap: () => _handleProfileAction(item['title'] as String),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: AppTheme.spaceMD),
                            Text(
                              item['title'] as String,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final verifications = [
      {
        'title': 'Email address',
        'verified': _profile?['email_verified'] == true,
        'value': _profile?['email'] ?? 'Not added',
      },
      {
        'title': 'Phone number',
        'verified': _profile?['phone_verified'] == true,
        'value': _profile?['phone'] ?? 'Not added',
      },
      {
        'title': 'Government ID',
        'verified': _hasVerifiedDocument(),
        'value': _hasVerifiedDocument() ? 'Verified' : 'Not verified',
      },
    ];

    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have a Verified Profile',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.statusSuccess,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          for (final verification in verifications)
            _buildVerificationItem(
              verification['title'] as String,
              verification['verified'] as bool,
              verification['value'] as String,
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String title, bool isVerified, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isVerified ? AppTheme.statusSuccess : AppTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                Text(value, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelPreferencesCard() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('About you', style: AppTheme.headingSmall),
              GestureDetector(
                onTap: () => _navigateToEditProfile(),
                child: Text(
                  'Edit',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          if (_profile?['bio'] != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Text(_profile!['bio'], style: AppTheme.bodyMedium),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.add, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: AppTheme.spaceMD),
                GestureDetector(
                  onTap: () => _navigateToEditProfile(),
                  child: Text(
                    'Add a mini bio',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehiclesSection() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vehicles', style: AppTheme.headingSmall),
              GestureDetector(
                onTap: _addVehicle,
                child: Text(
                  'Add vehicle',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          if (_vehicles.isEmpty) ...[
            Text(
              'No vehicles added yet',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ] else ...[
            for (final vehicle in _vehicles) _buildVehicleItem(vehicle),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleItem(Map<String, dynamic> vehicle) {
    final isCommercial = vehicle['vehicle_type'] == 'commercial';
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: isCommercial ? AppTheme.accentOrange.withOpacity(0.1) : AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              Icons.directions_car,
              color: isCommercial ? AppTheme.accentOrange : AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle['make']} ${vehicle['model']}',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  vehicle['plate_number'],
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
                if (isCommercial)
                  Container(
                    margin: const EdgeInsets.only(top: AppTheme.spaceXS),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.spaceXS),
                    ),
                    child: Text(
                      'Commercial',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.accentOrange,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (vehicle['is_verified'] == true)
            const Icon(Icons.verified, color: AppTheme.statusSuccess, size: 20),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spaceLG),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: AppTheme.primaryGradient(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: AppTheme.spaceXS),
                Text('₹0.00', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
            ),
            child: const Text('Open Wallet'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _buildSettingsCard('Security', [
      {'icon': Icons.lock, 'title': 'Password', 'subtitle': 'Change your account password', 'action': 'password'},
    ]);
  }

  Widget _buildNotificationsCard() {
    return _buildSettingsCard('Notifications', [
      {'icon': Icons.notifications, 'title': 'Push Notifications', 'subtitle': 'Manage notification preferences', 'action': 'notifications'},
    ]);
  }

  Widget _buildPrivacyCard() {
    return _buildSettingsCard('Privacy', [
      {'icon': Icons.visibility, 'title': 'Profile Visibility', 'subtitle': 'Control who can see your profile', 'action': 'privacy'},
    ]);
  }

  Widget _buildHelpCard() {
    return _buildSettingsCard('Help & Support', [
      {'icon': Icons.help, 'title': 'Help Center', 'subtitle': 'Get help and find answers', 'action': 'help'},
    ]);
  }

  Widget _buildSettingsCard(String title, List<Map<String, dynamic>> items) {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spaceLG),
          for (final item in items)
            _buildAccountItem(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              onTap: () => _handleSettingsAction(item['action'] as String),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 24),
            const SizedBox(width: AppTheme.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.bodyMedium),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _isProfileVerified() {
    final emailVerified = _profile?['email_verified'] == true;
    final phoneVerified = _profile?['phone_verified'] == true;
    final hasDocument = _hasVerifiedDocument();
    return emailVerified && phoneVerified && hasDocument;
  }

  bool _hasVerifiedDocument() {
    return _kyc.any((doc) => doc['verification_status'] == 'approved');
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          api: widget.api,
          profile: _profile,
          onProfileUpdated: (updatedProfile) {
            setState(() {
              _profile = updatedProfile;
            });
          },
        ),
      ),
    );
  }

  void _handleProfileAction(String action) {
    switch (action) {
      case 'Add phone number':
      case 'Verify email':
      case 'Add travel preferences':
        _navigateToEditProfile();
        break;
      case 'Add vehicle':
        _addVehicle();
        break;
      case 'Verify ID document':
        _uploadDocument();
        break;
    }
  }

  void _handleSettingsAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${action.substring(0, 1).toUpperCase()}${action.substring(1)} feature coming soon'),
        backgroundColor: AppTheme.statusInfo,
      ),
    );
  }

  void _addVehicle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add vehicle feature coming soon'),
        backgroundColor: AppTheme.statusInfo,
      ),
    );
  }

  void _uploadDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document upload feature coming soon'),
        backgroundColor: AppTheme.statusInfo,
      ),
    );
  }
}