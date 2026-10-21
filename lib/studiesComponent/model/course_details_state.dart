import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:dio/dio.dart';

enum CourseDetailsStatus { loading, loaded, failed }

class CourseFailure implements Exception {
  const CourseFailure(this.messageKey, {this.statusCode});
  final String messageKey;
  final int? statusCode;
  factory CourseFailure.from(Object error) {
    if (error is CourseFailure) return error;
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        return CourseFailure('courseAccessError', statusCode: code);
      }
      if (code == 404) return const CourseFailure('courseNotFoundError');
      if (code != null) {
        return CourseFailure('courseRequestError', statusCode: code);
      }
      return const CourseFailure('courseNetworkError');
    }
    if (error is FormatException) {
      return const CourseFailure('courseResponseError');
    }
    return const CourseFailure('courseRequestError');
  }
}

class CourseDetailsState {
  const CourseDetailsState.loading()
    : status = CourseDetailsStatus.loading,
      details = null,
      fetchedAt = null,
      error = null;
  const CourseDetailsState.loaded(this.details, this.fetchedAt)
    : status = CourseDetailsStatus.loaded,
      error = null;
  const CourseDetailsState.failed(this.error)
    : status = CourseDetailsStatus.failed,
      details = null,
      fetchedAt = null;
  final CourseDetailsStatus status;
  final PublicCourseDetails? details;
  final DateTime? fetchedAt;
  final CourseFailure? error;
}
