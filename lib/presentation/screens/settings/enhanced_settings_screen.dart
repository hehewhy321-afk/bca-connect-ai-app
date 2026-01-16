import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/skeleton_loader.dart';
import 'dart:io';

class EnhancedSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends ConsumerState<EnhancedSettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _changingPassword = false;
  late TabController _tabController;
  
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
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        _showSuccessSnackbar('Avatar updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        _showErrorSnackbar('Error uploading avatar: $e');
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
        _showSuccessSnackbar('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showErrorSnackbar('Error updating profile: $e');
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showErrorSnackbar('Please fill in all password fields');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackbar('Password must be at least 6 characters');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match');
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
        _showSuccessSnackbar('Password changed successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _changingPassword = false);
        _showErrorSnackbar('Error changing password: $e');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.close_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    ListItemSkeleton(),
                    SizedBox(height: 16),
                    ListItemSkeleton(),
                    SizedBox(height: 16),
                    ListItemSkeleton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern AppBar with Profile Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 40),
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _avatarUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      _avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          _getInitials(_fullNameController.text),
                                          style: TextStyle(
                                            color: ModernTheme.primaryOrange,
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(_fullNameController.text),
                                      style: TextStyle(
                                        color: ModernTheme.primaryOrange,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          if (_uploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.camera5,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name and Email
                      Text(
                        _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Your Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_email != null)
                        Text(
                          _email!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: ModernTheme.primaryOrange,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: ModernTheme.primaryOrange,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Iconsax.user), text: 'Personal'),
                  Tab(icon: Icon(Iconsax.book), text: 'Academic'),
                  Tab(icon: Icon(Iconsax.lock), text: 'Security'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildAcademicTab(),
                _buildSecurityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModernCard(
              child: Column(
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
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            _ModernCard(
              child: Column(
                children: [
                  _ModernTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Iconsax.document_text,
                    hintText: 'Tell us about yourself...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _skillsController,
                    label: 'Skills',
                    icon: Iconsax.code,
                    hintText: 'Flutter, Java, Python',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            _ModernCard(
              child: Column(
                children: [
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
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saving ? null : _saveProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          const SizedBox(height: 20),

          if (_isAlumni) ...[
            _ModernCard(
              child: Column(
                children: [
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
                    hintText: 'Software Engineer',
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: _currentCompanyController,
                    label: 'Current Company',
                    icon: Iconsax.building,
                    hintText: 'Company Name',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
          ],

          _ModernCard(
            child: Column(
              children: [
                _ModernTextField(
                  controller: _batchController,
                  label: 'Batch',
                  icon: Iconsax.calendar_1,
                  hintText: '2023-2027',
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
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saving ? null : _saveProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.1),
                  Colors.orange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.security_safe,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keep your account secure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          _ModernCard(
            child: Column(
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
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _changingPassword ? null : _changePassword,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _changingPassword
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.security_safe, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Update Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Modern UI Components
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _ModernCard extends StatelessWidget {
  final Widget child;

  const _ModernCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: ModernTheme.primaryOrange,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: ModernTheme.primaryOrange,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernTheme.primaryOrange.withValues(alpha: 0.1),
            const Color(0xFFFF9A3C).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.medal_star5,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I am an Alumni',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mark if you have graduated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAlumni,
            onChanged: onChanged,
            activeColor: ModernTheme.primaryOrange,
          ),
        ],
      ),
    );
  }
}
