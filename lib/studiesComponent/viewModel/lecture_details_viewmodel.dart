import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/studiesComponent/model/lecture.dart';
import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:campus_flutter/studiesComponent/service/public_course_service.dart';
import 'package:campus_flutter/studiesComponent/service/lecture_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

final lectureDetailsViewModel =
    Provider.family<
      LectureDetailsViewModel,
      (CalendarEvent?, Lecture?, String)
    >((ref, data) {
      final model = LectureDetailsViewModel(
        event: data.$1,
        lecture: data.$2,
        languageCode: data.$3,
      );
      ref.onDispose(model.dispose);
      return model;
    });

class LectureDetailsViewModel {
  final state = BehaviorSubject<CourseDetailsState>.seeded(
    const CourseDetailsState.loading(),
  );
  final CalendarEvent? event;
  final Lecture? lecture;
  final Future<(DateTime, PublicCourseDetails)> Function(String, bool)
  _fetchPublicDetails;
  final Future<String?> Function(String) _resolvePublicCourseId;
  int _request = 0;
  LectureDetailsViewModel({
    this.event,
    this.lecture,
    String languageCode = 'en',
    Future<(DateTime, PublicCourseDetails)> Function(String, bool)?
    fetchPublicDetails,
    Future<String?> Function(String)? resolvePublicCourseId,
  }) : _fetchPublicDetails =
           fetchPublicDetails ??
           ((id, forced) => PublicCourseService.instance.fetch(
             id,
             forced,
             languageCode: languageCode,
           )),
       _resolvePublicCourseId =
           resolvePublicCourseId ??
           PublicCourseService.instance.resolveCourseId;
  void dispose() {
    _request++;
    state.close();
  }

  Future<void> fetch(bool forcedRefresh) async {
    if (state.isClosed) return;
    final request = ++_request;
    state.add(const CourseDetailsState.loading());
    try {
      var courseId = LectureLinks.courseId(
        calendarUrl: event?.url,
        offeringId: lecture?.id,
      );
      if (courseId == null && event?.url != null) {
        courseId = await _resolvePublicCourseId(event!.url!);
      }
      if (courseId == null) throw const CourseFailure('courseLinkError');
      final response = await _fetchPublicDetails(courseId, forcedRefresh);
      if (response.$2.id != courseId) {
        throw const CourseFailure('courseIdentityError');
      }
      if (!state.isClosed && request == _request) {
        state.add(CourseDetailsState.loaded(response.$2, response.$1));
      }
    } catch (error) {
      if (!state.isClosed && request == _request) {
        state.add(CourseDetailsState.failed(CourseFailure.from(error)));
      }
    }
  }
}
