import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import 'dart:io';

class EnhancedSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends ConsumerState<EnhancedSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _changingPassword = false;
  
  // Form fields
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _batchController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _avatarUrl;
  String? _email;
  int? _semester;
  bool _isAlumni = false;
  int? _graduationYear;
  final _currentCompanyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _batchController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentCompanyController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _fullNameController.text = response['full_name'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          _batchController.text = response['batch'] ?? '';
          _bioController.text = response['bio'] ?? '';
          _githubController.text = response['github_url'] ?? '';
          _linkedinController.text = response['linkedin_url'] ?? '';
          _avatarUrl = response['avatar_url'];
          _email = user.email;
          _semester = response['semester'];
          _isAlumni = response['is_alumni'] ?? false;
          _graduationYear = response['graduation_year'];
          _currentCompanyController.text = response['current_company'] ?? '';
          _jobTitleController.text = response['job_title'] ?? '';
          
          final skills = response['skills'] as List?;
          if (skills != null) {
            _skillsController.text = skills.join(', ');
          }
          
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _uploadingAvatar = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final bytes = await File(image.path).readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';

      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(filePath, bytes);

      final publicUrl = SupabaseConfig.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      await SupabaseConfig.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          _uploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await SupabaseConfig.client.from('profiles').update({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'batch': _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
        'semester': _isAlumni ? null : _semester,
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'skills': skills.isEmpty ? null : skills,
        'github_url': _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
        'linkedin_url': _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
        'is_alumni': _isAlumni,
        'graduation_year': _isAlumni ? _graduationYear : null,
        'current_company': _isAlumni && _currentCompanyController.text.trim().isNotEmpty 
            ? _currentCompanyController.text.trim() 
            : null,
        'job_title': _isAlumni && _jobTitleController.text.trim().isNotEmpty 
            ? _jobTitleController.text.trim() 
            : null,
      }).eq('user_id', user.id);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all password fields')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _changingPassword = true);

    try {
      final response = await SupabaseConfig.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      if (response.user == null) throw Exception('Failed to update password');

      if (mounted) {
        setState(() {
          _changingPassword = false;
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _changingPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing password: $e')),
        );
      }
    }
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase()
        .substring(0, 2.clamp(0, name.length));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.refresh,
              color: ModernTheme.primaryOrange,
            ),
            onPressed: () {
              setState(() => _loading = true);
              _fetchProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              _ProfilePictureSection(
                avatarUrl: _avatarUrl,
                fullName: _fullNameController.text,
                email: _email,
                uploadingAvatar: _uploadingAvatar,
                onPickImage: _pickAndUploadAvatar,
                getInitials: _getInitials,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 32),

              // Personal Information
              _SectionHeader(title: 'Personal Information'),
              const SizedBox(height: 12),
              _FormSection(
                children: [
                  _ModernTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Iconsax.user,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Iconsax.call,
                    hintText: '+977 98XXXXXXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    initialValue: _email,
                    label: 'Email',
                    icon: Iconsax.sms,
                    enabled: false,
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: 0.2),

              const SizedBox(height: 24),

              // Academic Information
              _SectionHeader(title: 'Academic Information'),
              const SizedBox(height: 12),
              _FormSection(
                children: [
                  // Alumni Toggle
                  _AlumniToggle(
                    isAlumni: _isAlumni,
                    onChanged: (value) {
                      setState(() {
                        _isAlumni = value;
                        if (!value) {
                          _graduationYear = null;
                          _currentCompanyController.clear();
                          _jobTitleController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  if (_isAlumni) ...[
                    _ModernDropdown<int>(
                      value: _graduationYear,
                      label: 'Graduation Year',
                      icon: Iconsax.calendar,
                      items: List.generate(20, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) => setState(() => _graduationYear = value),
                    ),
                    const SizedBox(height: 20),
                    _ModernTextField(
                      controller: _jobTitleController,
                      label: 'Job Title',
                      icon: Iconsax.briefcase,
                    ),
                    const SizedBox(height: 20),
                    _ModernTextField(
                      controller: _currentCompanyController,
                      label: 'Current Company',
                      icon: Iconsax.building,
                    ),
                    const SizedBox(height: 20),
                  ],

                  _ModernTextField(
                    controller: _batchController,
                    label: 'Batch',
                    icon: Iconsax.calendar_1,
                    hintText: 'e.g., 2023-2027',
                  ),
                  if (!_isAlumni) ...[
                    const SizedBox(height: 20),
                    _ModernDropdown<int>(
                      value: _semester,
                      label: 'Semester',
                      icon: Iconsax.book,
                      items: List.generate(8, (index) {
                        final sem = index + 1;
                        return DropdownMenuItem(
                          value: sem,
                          child: Text('Semester $sem'),
                        );
                      }),
                      onChanged: (value) => setState(() => _semester = value),
                    ),
                  ],
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: 0.2),

              const SizedBox(height: 24),

              // Additional Information
              _SectionHeader(title: 'Additional Information'),
              const SizedBox(height: 12),
              _FormSection(
                children: [
                  _ModernTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Iconsax.document_text,
                    hintText: 'Tell us about yourself...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _skillsController,
                    label: 'Skills',
                    icon: Iconsax.code,
                    hintText: 'e.g., Flutter, Java, Python',
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _githubController,
                    label: 'GitHub URL',
                    icon: Iconsax.code_circle,
                    hintText: 'https://github.com/username',
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _linkedinController,
                    label: 'LinkedIn URL',
                    icon: Iconsax.link,
                    hintText: 'https://linkedin.com/in/username',
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideX(begin: 0.2),

              const SizedBox(height: 32),

              // Save Profile Button
              SizedBox(
                width: double.infinity,
                child: _ModernButton(
                  text: 'Save Profile',
                  icon: Iconsax.tick_circle,
                  onPressed: _saving ? null : _saveProfile,
                  isLoading: _saving,
                  isPrimary: true,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),

              // Security Section
              _SectionHeader(title: 'Security'),
              const SizedBox(height: 12),
              _FormSection(
                children: [
                  _ModernTextField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    icon: Iconsax.lock,
                    obscureText: !_showNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_showNewPassword ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Iconsax.lock,
                    obscureText: !_showConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideX(begin: 0.2),

              const SizedBox(height: 32),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                child: _ModernButton(
                  text: 'Change Password',
                  icon: Iconsax.security_safe,
                  onPressed: _changingPassword ? null : _changePassword,
                  isLoading: _changingPassword,
                  isPrimary: false,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern UI Components
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final List<Widget> children;

  const _FormSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ProfilePictureSection extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  final String? email;
  final bool uploadingAvatar;
  final VoidCallback onPickImage;
  final String Function(String) getInitials;

  const _ProfilePictureSection({
    required this.avatarUrl,
    required this.fullName,
    required this.email,
    required this.uploadingAvatar,
    required this.onPickImage,
    required this.getInitials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: ModernTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              getInitials(fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          getInitials(fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              if (uploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: uploadingAvatar ? null : onPickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ModernTheme.orangeGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Iconsax.camera,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isNotEmpty ? fullName : 'Your Name',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String label;
  final String? hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;

  const _ModernTextField({
    this.controller,
    this.initialValue,
    required this.label,
    this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ModernTheme.primaryOrange,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _ModernDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const _ModernDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ModernTheme.primaryOrange,
            width: 2,
          ),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _AlumniToggle extends StatelessWidget {
  final bool isAlumni;
  final void Function(bool) onChanged;

  const _AlumniToggle({
    required this.isAlumni,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.medal_star,
              color: ModernTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I am an Alumni',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Mark if you have graduated',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: isAlumni,
            onChanged: onChanged,
            activeTrackColor: ModernTheme.primaryOrange,
          ),
        ],
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;

  const _ModernButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(text),
        style: FilledButton.styleFrom(
          backgroundColor: ModernTheme.primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ModernTheme.primaryOrange,
                ),
              )
            : Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: ModernTheme.primaryOrange,
          side: BorderSide(color: ModernTheme.primaryOrange),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}