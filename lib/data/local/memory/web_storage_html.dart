// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, dangling_library_doc_comments
/// Implémentation réelle accédant à window.localStorage et aux fichiers sur le Web
library;

import 'dart:async';
import 'dart:convert';
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

/// Télécharge un fichier texte via le navigateur (sauvegarde JSON)
void downloadTextFile(String fileName, String content) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

/// Ouvre le sélecteur de fichier du navigateur et retourne le texte du fichier choisi
Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()..accept = '.json,application/json';
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      if (!completer.isCompleted) completer.complete(reader.result as String?);
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsText(files.first);
  });
  input.click();
  return completer.future;
}

/// Recharge la page (relecture du localStorage après un import)
void reloadPage() {
  html.window.location.reload();
}
