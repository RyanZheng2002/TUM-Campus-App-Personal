import 'package:campus_flutter/base/util/custom_back_button.dart';
import 'package:campus_flutter/base/util/color_picker_view.dart';
import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/calendarComponent/viewModels/calendar_viewmodel.dart';
import 'package:campus_flutter/calendarComponent/views/visibility_button_view.dart';
import 'package:campus_flutter/studiesComponent/model/lecture.dart';
import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/lecture_recovery_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/public_course_details_view.dart';
import 'package:campus_flutter/studiesComponent/viewModel/lecture_details_viewmodel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LectureDetailsScaffold extends ConsumerWidget {
  const LectureDetailsScaffold({
    super.key,
    this.scrollController,
    this.event,
    this.lecture,
  });
  final CalendarEvent? event;
  final Lecture? lecture;
  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const CustomBackButton(),
      actions: event == null
          ? null
          : [
              VisibilityButtonView(
                id: event!.lvNr ?? event!.id,
                isVisible: event!.isVisible,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ColorPickerView(
                  color: event!.getColor(),
                  onColorChanged: (color) => ref
                      .read(calendarViewModel)
                      .setEventColor(event!.lvNr ?? event!.id, color),
                ),
              ),
            ],
    ),
    body: LectureDetailsView(
      event: event,
      lecture: lecture,
      scrollController: scrollController,
    ),
  );
}

class LectureDetailsView extends ConsumerStatefulWidget {
  const LectureDetailsView({
    super.key,
    this.scrollController,
    this.event,
    this.lecture,
  });
  final CalendarEvent? event;
  final Lecture? lecture;
  final ScrollController? scrollController;
  @override
  ConsumerState<LectureDetailsView> createState() => _LectureDetailsViewState();
}

class _LectureDetailsViewState extends ConsumerState<LectureDetailsView> {
  late Provider<LectureDetailsViewModel> viewModel;
  String? _language;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.locale.languageCode;
    if (_language != language) {
      _language = language;
      viewModel = lectureDetailsViewModel((
        widget.event,
        widget.lecture,
        language,
      ));
      ref.read(viewModel).fetch(false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<CourseDetailsState>(
    stream: ref.watch(viewModel).state,
    initialData: ref.read(viewModel).state.value,
    builder: (context, snapshot) {
      final state = snapshot.data!;
      return switch (state.status) {
        CourseDetailsStatus.loading => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        CourseDetailsStatus.failed => LectureErrorView(
          error: state.error!,
          onRetry: () => ref.read(viewModel).fetch(true),
        ),
        CourseDetailsStatus.loaded => PublicCourseDetailsView(
          details: state.details!,
          fetchedAt: state.fetchedAt,
          event: widget.event,
          onRefresh: () => ref.read(viewModel).fetch(true),
          scrollController: widget.scrollController,
        ),
      };
    },
  );
}
