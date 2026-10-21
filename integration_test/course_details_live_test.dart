import 'package:campus_flutter/base/theme/light_theme.dart';
import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:campus_flutter/studiesComponent/service/navigatum_links.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/lecture_details_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/lecture_recovery_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/location_link_view.dart';
import 'package:campus_flutter/studiesComponent/viewModel/lecture_details_viewmodel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/xml_decoder.dart';

// Live Android network test, with no injected HTTP responses or account token.
// Meeting metadata is a synthetic fixture; course details are fetched live.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => EasyLocalization.ensureInitialized());

  for (final item in [
    ('950944244', 'German as a Foreign Language B1.1', '3'),
    (
      '950945432',
      'Hypersonic Flows and Kinetic Theory of Gases(ED140018)',
      '2',
    ),
  ]) {
    testWidgets('Android calendar cLvNr -> live course ${item.$1}', (
      tester,
    ) async {
      final german = item.$1 == '950944244';
      final start = german ? '2026-10-20 11:00:00' : '2026-10-21 09:45:00';
      final end = german ? '2026-10-20 13:00:00' : '2026-10-21 11:15:00';
      final location = german
          ? '1.04, Seminarraum (4153.EG.001)'
          : '1639, Vortragsraum/Seminarraum (5506.01.639)';
      final event = CalendarEvents.fromJson(
        tumXmlToJson('''
<rowset><event>
<nr>1</nr><status>FT</status>
<url>https://campus.tum.de/tumonline/lv.detail?cLvNr=${item.$1}</url>
<title>Calendar event</title><description>fix; Abhaltung;</description>
<dtstart>$start</dtstart><dtend>$end</dtend>
<location>$location</location>
</event></rowset>'''),
      ).events.single;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('de')],
            startLocale: const Locale('en'),
            path: 'assets/translations',
            child: Builder(
              builder: (context) => MaterialApp(
                key: ValueKey(item.$1),
                debugShowCheckedModeBanner: false,
                theme: lightTheme(context),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  appBar: AppBar(title: const Text('Campus Personal')),
                  body: LectureDetailsView(event: event),
                ),
              ),
            ),
          ),
        ),
      );
      for (var attempt = 0; attempt < 150; attempt++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.text(item.$2).evaluate().isNotEmpty ||
            find.byType(LectureErrorView).evaluate().isNotEmpty) {
          break;
        }
      }
      final state = container
          .read(lectureDetailsViewModel((event, null, 'en')))
          .state
          .value;
      expect(
        state.status,
        CourseDetailsStatus.loaded,
        reason:
            'Live course error: ${state.error?.messageKey} ${state.error?.statusCode}',
      );
      expect(state.details!.id, item.$1);
      expect(state.details!.sws, item.$3);
      expect(state.details!.contents, isNotEmpty);
      expect(find.text(item.$2), findsOneWidget);
      expect(
        find.text(german ? '11:00 – 13:00' : '09:45 – 11:15'),
        findsOneWidget,
      );
      expect(find.byType(LocationLinkView), findsOneWidget);
      expect(find.text('fix; Abhaltung;'), findsNothing);
      expect(find.byType(LectureErrorView), findsNothing);
      expect(
        NavigaTumLinks.search(event.locations.single).toString(),
        german
            ? 'https://nav.tum.de/search?q=4153.EG.001'
            : 'https://nav.tum.de/search?q=5506.01.639',
      );
      expect(tester.takeException(), isNull);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('android-course-${item.$1}');
      await tester.scrollUntilVisible(
        find.text('Course Contents'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Course Contents').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('android-course-${item.$1}-contents');
    });
  }
}
