import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/event.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/event_feedback_dialog.dart';
import '../../providers/event_provider.dart';

final eventDetailProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final repo = EventRepository();
  return await repo.getEventById(eventId);
});

final isUserRegisteredProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final repo = EventRepository();
  return await repo.isUserRegistered(eventId);
});

class EnhancedEventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EnhancedEventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EnhancedEventDetailScreen> createState() => _EnhancedEventDetailScreenState();
}

class _EnhancedEventDetailScreenState extends ConsumerState<EnhancedEventDetailScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration(Event event) async {
    if (event.teamType == 'team') {
      await _showTeamRegistrationDialog(event);
    } else {
      await _showIndividualRegistrationDialog(event);
    }
  }

  Future<void> _showIndividualRegistrationDialog(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register for ${event.title}?'),
            const SizedBox(height: 16),
            if (event.registrationFee != null && event.registrationFee! > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ModernTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.wallet, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'NPR ${event.registrationFee!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ModernTheme.primaryOrange,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _submitRegistration(event, null, null);
    }
  }

  Future<void> _showTeamRegistrationDialog(Event event) async {
    final teamNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final teamMembers = <Map<String, String>>[];
    teamMembers.add({'name': '', 'email': '', 'phone': ''});

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.people, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Team Registration'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      prefixIcon: const Icon(Iconsax.edit),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter team name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.info_circle, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Team size: ${event.teamSizeMin}-${event.teamSizeMax} members',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Team Members (${teamMembers.length}/${event.teamSizeMax})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(teamMembers.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: ModernTheme.orangeGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Member ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (index > 0)
                                IconButton(
                                  icon: const Icon(Iconsax.trash, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      teamMembers.removeAt(index);
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: const Icon(Iconsax.user, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) => teamMembers[index]['name'] = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Iconsax.sms, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) => teamMembers[index]['email'] = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (!value.contains('@')) {
                                return 'Invalid email';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  if (teamMembers.length < event.teamSizeMax)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          teamMembers.add({'name': '', 'email': '', 'phone': ''});
                        });
                      },
                      icon: const Icon(Iconsax.add_circle, size: 18),
                      label: const Text('Add Member'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (event.registrationFee != null && event.registrationFee! > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: ModernTheme.orangeGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Fee',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'NPR ${event.registrationFee!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (teamMembers.length < event.teamSizeMin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Minimum ${event.teamSizeMin} members required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'teamName': teamNameController.text,
                    'teamMembers': teamMembers,
                  });
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: ModernTheme.primaryOrange,
              ),
              child: const Text('Register Team'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _submitRegistration(
        event,
        result['teamName'],
        result['teamMembers'],
      );
    }
  }

  Future<void> _submitRegistration(
    Event event,
    String? teamName,
    List<Map<String, String>>? teamMembers,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Processing Registration...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );

      final repo = EventRepository();
      await repo.registerForEvent(
        eventId: event.id,
        teamName: teamName,
        teamMembers: teamMembers,
      );

      ref.invalidate(isUserRegisteredProvider(event.id));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle5, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    teamName != null
                        ? 'Team "$teamName" registered successfully!'
                        : 'Registered successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final isRegisteredAsync = ref.watch(isUserRegisteredProvider(widget.eventId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.info_circle, size: 64, color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Event not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.arrow_left),
                    label: const Text('Go Back'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ModernTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with Parallax Effect
                Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(0, _scrollOffset * 0.5),
                      child: Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: event.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(event.imageUrl!),
                                  fit: BoxFit.cover,
                                  onError: (error, stackTrace) {},
                                )
                              : null,
                          gradient: event.imageUrl == null
                              ? ModernTheme.orangeGradient
                              : null,
                        ),
                        child: event.imageUrl == null
                            ? const Center(
                                child: Icon(Iconsax.gallery, size: 80, color: Colors.white),
                              )
                            : null,
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Floating Status Badge
                    Positioned(
                      top: 80,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(event.status).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                    ),
                  ],
                ),

                // Content Card with Negative Margin
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & Category
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                height: 1.2,
                                              ),
                                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                ModernTheme.primaryOrange.withValues(alpha: 0.2),
                                                ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Iconsax.category, size: 14, color: ModernTheme.primaryOrange),
                                              const SizedBox(width: 6),
                                              Text(
                                                event.category,
                                                style: const TextStyle(
                                                  color: ModernTheme.primaryOrange,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Date & Time Info Card (similar to events list)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Iconsax.calendar_1,
                                          size: 20,
                                          color: ModernTheme.primaryOrange,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Start',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('MMM dd, yyyy • hh:mm a').format(event.startDate),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (event.endDate != null) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.calendar_tick,
                                            size: 20,
                                            color: ModernTheme.primaryOrange,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'End',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('MMM dd, yyyy • hh:mm a').format(event.endDate!),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                              const SizedBox(height: 20),

                              // Location & Fee Row
                              Row(
                                children: [
                                  // Location
                                  if (event.location != null)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Iconsax.location,
                                              size: 20,
                                              color: ModernTheme.primaryOrange,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Location',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    event.location!,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Fee
                                  if (event.registrationFee != null && event.registrationFee! > 0) ...[
                                    if (event.location != null) const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: ModernTheme.orangeGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(Iconsax.wallet, color: Colors.white, size: 20),
                                          const SizedBox(height: 8),
                                          Text(
                                            'NPR ${event.registrationFee!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                              const SizedBox(height: 24),

                              // Team Info (if applicable)
                              if (event.teamType == 'team') ...[
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Iconsax.people, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Team Event',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Team size: ${event.teamSizeMin}-${event.teamSizeMax} members',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                                const SizedBox(height: 24),
                              ],

                              // About Section
                              Text(
                                'About Event',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event.description ?? 'No description available',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 24),

                              // Gallery Section
                              if (event.galleryImages.isNotEmpty || event.imageUrl != null) ...[
                                Text(
                                  'Event Gallery',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),

                        // Gallery Horizontal Scroll
                        if (event.galleryImages.isNotEmpty || event.imageUrl != null)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: event.galleryImages.isNotEmpty ? event.galleryImages.length : 3,
                              itemBuilder: (context, index) {
                                final imageUrl = event.galleryImages.isNotEmpty 
                                    ? event.galleryImages[index]
                                    : event.imageUrl;
                                
                                return Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: imageUrl != null
                                        ? CachedImage(
                                            imageUrl: imageUrl,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            borderRadius: BorderRadius.circular(20),
                                            errorWidget: Container(
                                              decoration: const BoxDecoration(
                                                gradient: ModernTheme.orangeGradient,
                                              ),
                                              child: const Center(
                                                child: Icon(Iconsax.gallery, color: Colors.white, size: 48),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: const BoxDecoration(
                                              gradient: ModernTheme.orangeGradient,
                                            ),
                                            child: const Center(
                                              child: Icon(Iconsax.gallery, color: Colors.white, size: 48),
                                            ),
                                          ),
                                  ),
                                ).animate(delay: Duration(milliseconds: 100 * index))
                                    .fadeIn()
                                    .slideX(begin: 0.2);
                              },
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Organizer Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organized By',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: ModernTheme.orangeGradient,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Iconsax.building, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Association Team',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Event Organizers',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.danger, size: 64, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => ref.invalidate(eventDetailProvider(widget.eventId)),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: ModernTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: eventAsync.maybeWhen(
        data: (event) {
          if (event == null) return null;
          
          // Show feedback button for completed events if user is registered
          if (event.status.toLowerCase() == 'completed') {
            return isRegisteredAsync.when(
              data: (isRegistered) {
                if (!isRegistered) return null;
                
                // Check if user has given feedback
                final feedbackAsync = ref.watch(userFeedbackProvider(event.id));
                return feedbackAsync.when(
                  data: (existingFeedback) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: existingFeedback != null
                              ? LinearGradient(
                                  colors: [Colors.green.shade600, Colors.green.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : ModernTheme.orangeGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (existingFeedback != null ? Colors.green : ModernTheme.primaryOrange)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => EventFeedbackDialog(
                                  eventId: event.id,
                                  eventTitle: event.title,
                                  existingFeedback: existingFeedback,
                                  onSuccess: () {
                                    ref.invalidate(userFeedbackProvider(event.id));
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    existingFeedback != null ? Iconsax.edit5 : Iconsax.star5,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    existingFeedback != null
                                        ? 'Update Feedback'
                                        : 'Rate This Event',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (existingFeedback != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Iconsax.star5, color: Colors.white, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${existingFeedback['rating']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  loading: () => Container(
                    padding: const EdgeInsets.all(20),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => null,
                );
              },
              loading: () => null,
              error: (error, stackTrace) => null,
            );
          }
          
          // Show register button for non-completed events
          return isRegisteredAsync.when(
                data: (isRegistered) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: isRegistered
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Already Registered',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: ModernTheme.orangeGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: ModernTheme.primaryOrange.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _handleRegistration(event),
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Iconsax.ticket, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Register Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (event.registrationFee != null && event.registrationFee! > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'NPR ${event.registrationFee!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                loading: () => Container(
                  padding: const EdgeInsets.all(20),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Container(
                  padding: const EdgeInsets.all(20),
                  child: SafeArea(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: ModernTheme.orangeGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ModernTheme.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleRegistration(event),
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.ticket, color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Register Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
        },
        orElse: () => null,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFF3B82F6);
      case 'ongoing':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF6B7280);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
