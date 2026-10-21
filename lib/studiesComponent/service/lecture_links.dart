/// Explicit TUMonline course identifiers. Calendar lv.detail links use cLvNr;
/// legacy LvNr and meeting pTerminNr must not be substituted for an offering.
class LectureLinks {
  static Uri? campusUri(String? url) {
    final text = url?.trim().replaceAll('&amp;', '&') ?? '';
    if (text.isEmpty) return null;
    var uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (!uri.hasScheme) {
      uri = Uri.https(
        'campus.tum.de',
        '/tumonline/',
      ).resolve(text.startsWith('tumonline/') ? '/$text' : text);
    }
    if (uri.scheme != 'https' ||
        uri.host != 'campus.tum.de' ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        !uri.path.startsWith('/tumonline/')) {
      return null;
    }
    return uri;
  }

  static String? courseId({String? calendarUrl, String? offeringId}) {
    if (offeringId != null && RegExp(r'^\d+$').hasMatch(offeringId)) {
      return offeringId;
    }
    final uri = campusUri(calendarUrl);
    if (uri == null) return null;
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      final isCalendarCourse =
          uri.path.toLowerCase() == '/tumonline/lv.detail' && key == 'clvnr';
      if ((key == 'pstpspnr' || isCalendarCourse) &&
          RegExp(r'^\d{1,12}$').hasMatch(entry.value)) {
        return entry.value;
      }
    }
    final match = RegExp(
      r'/slc\.tm\.cp/(?:student/courses|course)/(\d+)(?:[/?#]|$)',
    ).firstMatch('${uri.path}#${uri.fragment}');
    return match?.group(1);
  }

  static String? lvNumber(String? url) {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null) return null;
    for (final entry in uri.queryParameters.entries) {
      if (const ['lvnr', 'plvnr', 'clvnr'].contains(entry.key.toLowerCase()) &&
          RegExp(r'^\d+$').hasMatch(entry.value)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Keep navigation on the university host and never forward an API token.
  static Uri? coursePage({String? calendarUrl, String? offeringId}) {
    final uri = campusUri(calendarUrl);
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'campus.tum.de' &&
        uri.userInfo.isEmpty &&
        (!uri.hasPort || uri.port == 443) &&
        uri.path.startsWith('/tumonline/') &&
        !uri.path.toLowerCase().contains('wbservicesbasic.')) {
      final modernId = courseId(calendarUrl: calendarUrl);
      if (modernId != null) {
        return Uri.https(
          'campus.tum.de',
          '/tumonline/ee/ui/ca2/app/desktop/',
        ).replace(fragment: '/slc.tm.cp/student/courses/$modernId');
      }
      return uri.replace(
        queryParameters: {
          for (final entry in uri.queryParameters.entries)
            if (const [
              'pstpspnr',
              'lvnr',
              'plvnr',
              'psprache',
              'pterminnr',
            ].contains(entry.key.toLowerCase()))
              entry.key: entry.value,
        },
        fragment: '',
      );
    }
    if (offeringId != null && RegExp(r'^\d+$').hasMatch(offeringId)) {
      return Uri.https('campus.tum.de', '/tumonline/wbLv.wbShowLVDetail', {
        'pStpSpNr': offeringId,
      });
    }
    return null;
  }

  static final home = Uri.https('campus.tum.de', '/tumonline/');
}
