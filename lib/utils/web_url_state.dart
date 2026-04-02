import 'package:flutter/foundation.dart';

class WebUrlState {
  final String path;
  final Map<String, String> queryParameters;

  const WebUrlState({
    required this.path,
    required this.queryParameters,
  });
}

WebUrlState resolveWebUrlState() {
  final base = Uri.base;
  var path = _normalizePath(base.path);
  var queryParameters = Map<String, String>.from(base.queryParameters);

  if (kIsWeb) {
    final fragment = base.fragment.trim();
    if (fragment.startsWith('/')) {
      final fragmentUri = Uri.parse(fragment);
      path = _normalizePath(fragmentUri.path);
      if (fragmentUri.queryParameters.isNotEmpty) {
        queryParameters = fragmentUri.queryParameters;
      }
    }
  }

  return WebUrlState(path: path, queryParameters: queryParameters);
}

String _normalizePath(String path) {
  var normalized = path.toLowerCase().trim();
  if (normalized.isEmpty) return '/';
  if (!normalized.startsWith('/')) normalized = '/$normalized';
  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}
