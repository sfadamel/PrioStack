import 'package:drift/drift.dart';

QueryExecutor openDriftConnection() {
  throw UnsupportedError(
    'Sur le Web (Chrome/Edge), PrioStack utilise InMemoryTaskRepository via le pattern Repository abstrait.',
  );
}
