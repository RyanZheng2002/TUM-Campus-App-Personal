import 'package:campus_flutter/base/util/url_launcher.dart';
import 'package:campus_flutter/studiesComponent/service/navigatum_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationLinkView extends ConsumerWidget {
  const LocationLinkView({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.location_on),
    title: Text(location),
    trailing: Tooltip(
      message: context.tr('openRoomInNavigaTUM'),
      child: const Icon(Icons.open_in_new, size: 20),
    ),
    onTap: () =>
        UrlLauncher.urlString(NavigaTumLinks.search(location).toString(), ref),
  );
}
