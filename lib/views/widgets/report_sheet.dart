import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';
import '../../services/api_service.dart';
import '../../services/moderation_api_service.dart';

const Map<String, String> _kReportReasons = {
  'spam': 'Spam',
  'harassment': 'Harassment or bullying',
  'hate_speech': 'Hate speech',
  'nudity': 'Nudity or sexual content',
  'violence': 'Violence or dangerous content',
  'fake_account': 'Fake account or impersonation',
  'self_harm': 'Self-harm',
  'other': 'Something else',
};

/// Opens the report flow: pick a reason, optionally add details, submit.
/// Shows its own success/error snackbar. Safe to call from any widget that
/// has a [BuildContext] mounted in the tree.
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ReportReasonSheet(),
  );

  if (reason == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ModerationApiService(ApiService()).reportContent(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Thanks — your report has been submitted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReportReasonSheet extends StatelessWidget {
  const _ReportReasonSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neutral500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Why are you reporting this?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final entry in _kReportReasons.entries)
            ListTile(
              title: Text(entry.value,
                  style: const TextStyle(color: AppColors.onSurface)),
              onTap: () => Navigator.pop(context, entry.key),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
