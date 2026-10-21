import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:campus_flutter/base/theme/light_theme.dart';
import 'package:campus_flutter/base/theme/dark_theme.dart';
import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/lecture_recovery_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/public_course_details_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/location_link_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LocalTranslations extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/en.json').readAsStringSync())
          as Map<String, dynamic>;
}

const _preview = ValueKey('course-preview');
Widget app(Widget body, {bool dark = false, double scale = 1}) => ProviderScope(
  child: EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    assetLoader: _LocalTranslations(),
    child: Builder(
      builder: (context) => MaterialApp(
        theme: lightTheme(context),
        darkTheme: darkTheme(context),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: _preview,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: body,
          ),
        ),
      ),
    ),
  ),
);
Future<void> preview(WidgetTester tester, String name) async {
  final output = Platform.environment['COURSE_UI_PREVIEW_DIR'];
  if (output == null) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_preview),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$output/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final details = PublicCourseDetails.fromXml(
    File('test/fixtures/public_course_950944244.xml').readAsStringSync(),
    expectedId: '950944244',
    languageCode: 'de',
  );
  final event = CalendarEvent(
    id: 'test-meeting',
    title: 'Deutsch als Fremdsprache B1.1 SE',
    status: 'CONFIRMED',
    startDate: DateTime(2026, 10, 20, 11),
    endDate: DateTime(2026, 10, 20, 13),
    locations: ['1.04, Seminarraum (4153.EG.001)'],
    description: 'fix; Abhaltung;',
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '../toolchain/flutter';
    for (final item in [
      ('Roboto', 'roboto-regular.ttf'),
      ('Roboto', 'roboto-medium.ttf'),
      ('Roboto', 'roboto-bold.ttf'),
      ('MaterialIcons', 'materialicons-regular.otf'),
    ]) {
      final file = File('$sdk/bin/cache/artifacts/material_fonts/${item.$2}');
      if (file.existsSync()) {
        final loader = FontLoader(item.$1)
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await loader.load();
      }
    }
  });
  testWidgets('valid B1.1 course is grouped and contains no fallback prose', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(PublicCourseDetailsView(details: details, event: event)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deutsch als Fremdsprache B1.1'), findsOneWidget);
    expect(find.text('11:00 – 13:00'), findsOneWidget);
    expect(find.byType(LocationLinkView), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Course teaching team'), findsOneWidget);
    expect(find.textContaining('Terezija Grgic'), findsOneWidget);
    expect(find.textContaining('Source:'), findsNothing);
    expect(find.textContaining('permission'), findsNothing);
    expect(find.text('fix; Abhaltung;'), findsNothing);
    expect(tester.takeException(), isNull);
    await preview(tester, 'lecture-ui-success');
  });
  testWidgets('failed details show only the error and retry', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    await tester.pumpWidget(
      app(
        LectureErrorView(
          error: const CourseFailure('courseAccessError', statusCode: 403),
          onRetry: () => retries++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HTTP 403'), findsOneWidget);
    expect(find.byType(LocationLinkView), findsNothing);
    expect(find.text('Deutsch als Fremdsprache B1.1'), findsNothing);
    expect(find.textContaining('Source:'), findsNothing);
    expect(find.textContaining('Settings'), findsNothing);
    await preview(tester, 'lecture-ui-error');
    await tester.tap(find.byIcon(Icons.refresh));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dark mode and enlarged text have no overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        PublicCourseDetailsView(details: details, event: event),
        dark: true,
        scale: 1.4,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, 'lecture-ui-dark');
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, -650),
      1000,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
