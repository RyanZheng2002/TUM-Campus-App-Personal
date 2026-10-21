import 'package:campus_flutter/base/routing/routes.dart';
import 'package:campus_flutter/base/util/hyperlink_text.dart';
import 'package:campus_flutter/base/util/last_updated_text.dart';
import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/calendarComponent/services/calendar_service.dart';
import 'package:campus_flutter/studiesComponent/service/lecture_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Explicitly partial replacement for the personal lectures list during outages.
class CalendarLecturesRecoveryView extends StatefulWidget {
  const CalendarLecturesRecoveryView({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  State<CalendarLecturesRecoveryView> createState() =>
      _CalendarLecturesRecoveryViewState();
}

class _CalendarLecturesRecoveryViewState
    extends State<CalendarLecturesRecoveryView> {
  late final Future<(DateTime?, List<CalendarEvent>)> _calendar;

  @override
  void initState() {
    super.initState();
    _calendar = CalendarService.fetchCalendar(false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.tr('lectureCalendarList'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(context.tr('lectureCalendarListHint')),
        HyperLinkListTile(
          link: LectureLinks.home.toString(),
          label: context.tr('openTUMonline'),
        ),
        TextButton.icon(
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('tryAgain')),
        ),
        FutureBuilder(
          future: _calendar,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(context.tr('lectureCalendarUnavailable'));
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            // Keep all meetings and their original IDs. Do not infer a complete
            // enrollment list or merge lecture/exercise groups by title.
            final events =
                snapshot.data!.$2.where((event) => event.url != null).toList()
                  ..sort((a, b) => a.startDate.compareTo(b.startDate));
            return Column(
              children: [
                if (snapshot.data!.$1 != null)
                  LastUpdatedText(snapshot.data!.$1!),
                if (events.isEmpty)
                  Text(context.tr('lectureCalendarUnavailable')),
                for (final event in events)
                  ListTile(
                    title: Text(event.title ?? context.tr('lectureDetails')),
                    subtitle: Text(
                      '${event.timePeriodText(context)}\n'
                      '${event.locations.join(', ')}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(calendarDetails, extra: event),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
