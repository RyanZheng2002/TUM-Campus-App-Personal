import 'package:campus_flutter/base/util/hyperlink_text.dart';
import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/location_link_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/detailed_lecture_info_row_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PublicCourseDetailsView extends StatelessWidget {
  const PublicCourseDetailsView({
    super.key,
    required this.details,
    this.fetchedAt,
    this.event,
    this.onRefresh,
    this.scrollController,
  });
  final PublicCourseDetails details;
  final DateTime? fetchedAt;
  final CalendarEvent? event;
  final VoidCallback? onRefresh;
  final ScrollController? scrollController;

  Widget _card(
    BuildContext context, {
    required String title,
    required Widget child,
    IconData? icon,
  }) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .4),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );

  Widget _fact(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );

  Widget _section(
    BuildContext context,
    String title,
    String text, {
    bool expanded = false,
  }) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .4),
      ),
    ),
    child: ExpansionTile(
      initiallyExpanded: expanded,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [DetailedLectureInfoRowView(title: '', information: text)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = details;
    final colors = Theme.of(context).colorScheme;
    final dateValid = event == null || event!.endDate.isAfter(event!.startDate);
    final widgets = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              d.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 27,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              tooltip: context.tr('tryAgain'),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      if (d.courseType != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              d.courseType!,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      const SizedBox(height: 22),
      if (event != null) ...[
        _card(
          context,
          title: context.tr('thisMeeting'),
          icon: Icons.calendar_today_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!dateValid)
                Text(
                  context.tr('courseTimeError'),
                  style: TextStyle(color: colors.error),
                )
              else ...[
                Text(
                  DateFormat.yMMMEd(
                    context.locale.toString(),
                  ).format(event!.startDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  DateUtils.isSameDay(event!.startDate, event!.endDate)
                      ? '${DateFormat.Hm().format(event!.startDate)} – ${DateFormat.Hm().format(event!.endDate)}'
                      : '${DateFormat.Hm().format(event!.startDate)} – ${DateFormat.yMMMEd(context.locale.toString()).add_Hm().format(event!.endDate)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              if (event!.isCanceled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr('lectureMeetingCanceled'),
                    style: TextStyle(color: colors.error),
                  ),
                ),
              for (final location in event!.locations.where(
                (value) => value.trim().isNotEmpty,
              ))
                LocationLinkView(location: location),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      _card(
        context,
        title: context.tr('courseOverview'),
        icon: Icons.info_outline,
        child: Column(
          children: [
            if (d.courseCode != null)
              _fact(context, context.tr('publicCourseCode'), d.courseCode!),
            if (d.semester != null)
              _fact(context, context.tr('publicCourseSemester'), d.semester!),
            if (d.language != null)
              _fact(context, context.tr('language'), d.language!),
            if (d.sws != null) _fact(context, 'SWS', d.sws!),
            if (d.ects != null) _fact(context, 'ECTS', d.ects!),
          ],
        ),
      ),
      if (d.teachers.isNotEmpty || d.organisation != null) ...[
        const SizedBox(height: 14),
        _card(
          context,
          title: context.tr('courseTeachingTeam'),
          icon: Icons.people_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.teachers.isNotEmpty)
                SelectableText(
                  d.teachers.join(' · '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              if (d.organisation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SelectableText(
                    d.organisation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      for (final section in <(String, String?)>[
        ('courseContents', d.contents),
        ('courseObjective', d.objective),
        ('publicCourseRequirements', d.requirements),
        ('publicCourseTeachingMethod', d.teachingMethod),
        ('publicCourseAssessment', d.assessment),
        ('note', d.note),
      ])
        if (section.$2 != null && section.$2!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _section(
            context,
            context.tr(section.$1),
            section.$2!,
            expanded: section.$1 == 'courseContents',
          ),
        ],
      const SizedBox(height: 10),
      HyperLinkListTile(
        link:
            'https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/slc.tm.cp/student/courses/${d.id}',
        label: 'TUMonline',
      ),
      const SizedBox(height: 16),
    ];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: widgets,
          ),
        ),
      ),
    );
  }
}
