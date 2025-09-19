// lib/screens/profile_edit_screen.dart - BlaBlaCar Style Profile Edit
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../core/colors.dart';
import '../core/text_styles.dart';

class ProfileEditScreen extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic>? profile;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const ProfileEditScreen({
    super.key,
    required this.api,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  
  bool _loading = false;
  String? _selectedGender;
  String _chatPreference = 'talkative';
  String _musicPreference = 'depends';
  String _petsPreference = 'depends';
  String _smokingPreference = 'no';

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile?['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.profile?['phone'] ?? '');
    _bioController = TextEditingController(text: widget.profile?['bio'] ?? '');
    _addressController = TextEditingController(text: widget.profile?['address'] ?? '');
    _cityController = TextEditingController(text: widget.profile?['city'] ?? '');
    
    _selectedGender = widget.profile?['gender'];
    _chatPreference = widget.profile?['chat_preference'] ?? 'talkative';
    _musicPreference = widget.profile?['music_preference'] ?? 'depends';
    _petsPreference = widget.profile?['pets_preference'] ?? 'depends';
    _smokingPreference = widget.profile?['smoking_preference'] ?? 'no';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final updateData = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'gender': _selectedGender,
        'chat_preference': _chatPreference,
        'music_preference': _musicPreference,
        'pets_preference': _petsPreference,
        'smoking_preference': _smokingPreference,
      };

      print('Updating profile with data: $updateData');

      final response = await widget.api.post('/profile/update', updateData);
      
      if (response['user'] != null) {
        widget.onProfileUpdated(response['user']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Invalid response format');
      }

    } catch (e) {
      print('Profile update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionCard(
                title: 'Basic Information',
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.trim().length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildGenderDropdown(),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // About You
              _buildSectionCard(
                title: 'About You',
                children: [
                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio (Tell others about yourself)',
                    icon: Icons.chat_bubble_outline,
                    maxLines: 3,
                    hintText: 'I\'m chatty when I feel comfortable...',
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Location
              _buildSectionCard(
                title: 'Location',
                children: [
                  _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Travel Preferences (BlaBlaCar Style)
              _buildSectionCard(
                title: 'Travel Preferences',
                subtitle: 'Let others know what to expect when traveling with you',
                children: [
                  _buildPreferenceDropdown(
                    title: 'Chattiness',
                    value: _chatPreference,
                    options: const [
                      {'value': 'quiet', 'label': 'I\'m more of a quiet type'},
                      {'value': 'talkative', 'label': 'I\'m chatty when I feel comfortable'},
                      {'value': 'depends', 'label': 'It depends on my mood'},
                    ],
                    onChanged: (value) => setState(() => _chatPreference = value!),
                    icon: Icons.chat,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildPreferenceDropdown(
                    title: 'Music',
                    value: _musicPreference,
                    options: const [
                      {'value': 'yes', 'label': 'I love music during rides'},
                      {'value': 'no', 'label': 'I prefer quiet rides'},
                      {'value': 'depends', 'label': 'It depends'},
                    ],
                    onChanged: (value) => setState(() => _musicPreference = value!),
                    icon: Icons.music_note,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildPreferenceDropdown(
                    title: 'Pets',
                    value: _petsPreference,
                    options: const [
                      {'value': 'yes', 'label': 'I\'m happy to travel with pets'},
                      {'value': 'no', 'label': 'I\'d rather not travel with pets'},
                      {'value': 'depends', 'label': 'Depends on the pet'},
                    ],
                    onChanged: (value) => setState(() => _petsPreference = value!),
                    icon: Icons.pets,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildPreferenceDropdown(
                    title: 'Smoking',
                    value: _smokingPreference,
                    options: const [
                      {'value': 'no', 'label': 'No smoking'},
                      {'value': 'yes', 'label': 'Smoking allowed'},
                    ],
                    onChanged: (value) => setState(() => _smokingPreference = value!),
                    icon: Icons.smoke_free,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headline4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
      ],
      onChanged: (value) => setState(() => _selectedGender = value),
    );
  }

  Widget _buildPreferenceDropdown({
    required String title,
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.background,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(
                    option['label']!,
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}