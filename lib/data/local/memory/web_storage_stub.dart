/// Stub no-op pour les plateformes non-web (mobile/desktop VM)
String? getStorageItem(String key) => null;
void setStorageItem(String key, String value) {}
void removeStorageItem(String key) {}
void downloadTextFile(String fileName, String content) {}
Future<String?> pickTextFile() async => null;
void reloadPage() {}
