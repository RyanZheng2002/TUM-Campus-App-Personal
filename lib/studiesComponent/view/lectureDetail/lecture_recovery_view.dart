import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LectureErrorView extends StatelessWidget {
  const LectureErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final CourseFailure error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(error.messageKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (error.statusCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'HTTP ${error.statusCode}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('tryAgain')),
          ),
        ],
      ),
    ),
  );
}
