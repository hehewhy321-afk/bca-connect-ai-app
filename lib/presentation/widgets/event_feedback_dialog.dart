import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../data/repositories/event_repository.dart';

class EventFeedbackDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final Map<String, dynamic>? existingFeedback;
  final VoidCallback? onSuccess;

  const EventFeedbackDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.existingFeedback,
    this.onSuccess,
  });

  @override
  State<EventFeedbackDialog> createState() => _EventFeedbackDialogState();
}

class _EventFeedbackDialogState extends State<EventFeedbackDialog> {
  late int _rating;
  late TextEditingController _feedbackController;
  late bool _isAnonymous;
  bool _isSubmitting = false;
  int _hoveredRating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingFeedback?['rating'] ?? 0;
    _feedbackController = TextEditingController(
      text: widget.existingFeedback?['feedback'] ?? '',
    );
    _isAnonymous = widget.existingFeedback?['is_anonymous'] ?? false;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = EventRepository();
      await repo.submitFeedback(
        eventId: widget.eventId,
        rating: _rating,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle5, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.existingFeedback != null
                      ? 'Feedback updated successfully!'
                      : 'Thank you for your feedback!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA7809).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.star5,
                      color: Color(0xFFDA7809),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingFeedback != null
                              ? 'Update Your Feedback'
                              : 'Rate This Event',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.eventTitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Star Rating
              Column(
                children: [
                  Text(
                    'How would you rate this event?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isActive = star <= (_hoveredRating > 0 ? _hoveredRating : _rating);
                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredRating = star),
                        onExit: (_) => setState(() => _hoveredRating = 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _rating = star),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isActive ? Iconsax.star5 : Iconsax.star,
                              size: 40,
                              color: isActive
                                  ? const Color(0xFFFBBF24)
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (_rating > 0)
                    Text(
                      _getRatingLabel(_rating),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDA7809),
                          ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Feedback Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Feedback (Optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Share your experience, suggestions, or comments...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Colors.grey[100],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Anonymous Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit Anonymously',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your name won\'t be shown to others',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                      activeTrackColor: const Color(0xFFDA7809),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDA7809),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.send_1, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.existingFeedback != null
                                  ? 'Update Feedback'
                                  : 'Submit Feedback',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
