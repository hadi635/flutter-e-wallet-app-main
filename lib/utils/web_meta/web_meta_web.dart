// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

void setWebPageMeta({
  required String title,
  required String description,
}) {
  html.document.title = title;
  _upsertMeta(name: 'description', content: description);
  _upsertMeta(name: 'robots', content: 'index,follow');
  _upsertMeta(property: 'og:title', content: title);
  _upsertMeta(property: 'og:description', content: description);
  _upsertMeta(property: 'og:type', content: 'website');
}

void _upsertMeta({
  String? name,
  String? property,
  required String content,
}) {
  assert(name != null || property != null);
  final selector = name != null
      ? 'meta[name="$name"]'
      : 'meta[property="$property"]';
  final existing = html.document.head?.querySelector(selector);
  if (existing is html.MetaElement) {
    existing.content = content;
    return;
  }

  final meta = html.MetaElement()..content = content;
  if (name != null) meta.name = name;
  if (property != null) meta.setAttribute('property', property);
  html.document.head?.append(meta);
}
