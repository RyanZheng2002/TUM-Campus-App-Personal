class NavigaTumLinks {
  static Uri search(String location) {
    final room = RegExp(
      r'\b\d{4}\.[A-Za-z0-9-]{1,4}\.[A-Za-z0-9-]+\b',
    ).firstMatch(location)?.group(0);
    final query = room ?? location.trim();
    return Uri.https(
      'nav.tum.de',
      '/search',
      query.isEmpty ? null : {'q': query},
    );
  }
}
