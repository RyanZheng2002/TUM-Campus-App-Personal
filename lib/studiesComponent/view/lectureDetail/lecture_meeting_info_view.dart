import 'package:campus_flutter/studiesComponent/view/lectureDetail/location_link_view.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/lecture_info_card_view.dart';
import 'package:campus_flutter/studiesComponent/viewModel/lecture_details_viewmodel.dart';
import 'package:campus_flutter/studiesComponent/view/lectureDetail/basic_lecture_info_row_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LectureMeetingInfoView extends ConsumerWidget {
  const LectureMeetingInfoView({super.key, required this.viewModel});

  final Provider<LectureDetailsViewModel> viewModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LectureInfoCardView(
      icon: Icons.calendar_month,
      title: context.tr("thisMeeting"),
      widgets: [
        BasicLectureInfoRowView(
          information: ref.read(viewModel).event!.timePeriodText(context),
          iconData: Icons.hourglass_top,
        ),
        for (final location in ref.read(viewModel).event!.locations)
          LocationLinkView(location: location),
      ],
    );
  }
}
