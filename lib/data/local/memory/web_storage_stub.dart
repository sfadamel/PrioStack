// ignore_for_file: dangling_library_doc_comments
/// Stub no-op pour les plateformes non-web (mobile/desktop VM)
library;

import 'dart:async';

String? getStorageItem(String key) => null;
void setStorageItem(String key, String value) {}
void removeStorageItem(String key) {}
void downloadTextFile(String fileName, String content) {}
Future<String?> pickTextFile() async => null;
void reloadPage() {}
void broadcastSyncEvent(String message) {}
StreamSubscription? onSyncEvent(void Function() onEvent) => null;

