import 'web_meta_stub.dart' if (dart.library.html) 'web_meta_web.dart' as impl;

void setWebPageMeta({
  required String title,
  required String description,
}) {
  impl.setWebPageMeta(title: title, description: description);
}
