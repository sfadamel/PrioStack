// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, dangling_library_doc_comments
/// Implémentation réelle accédant à window.localStorage sur le Web
library;

import 'dart:html' as html;

String? getStorageItem(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void setStorageItem(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

void removeStorageItem(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}
