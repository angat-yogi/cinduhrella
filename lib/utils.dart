import 'package:cinduhrella/firebase_options.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/chat_service.dart';
import 'package:cinduhrella/services/closet_scanner_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:cinduhrella/services/mock_try_on_renderer.dart';
import 'package:cinduhrella/services/remote_try_on_renderer.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cinduhrella/services/try_on_renderer.dart';
import 'package:cinduhrella/services/try_on_service.dart';
import 'package:cinduhrella/services/wardrobe_engine_service.dart';
import 'package:cinduhrella/services/wardrobe_capture_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

Future<void> setupFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> registerServices() async {
  final GetIt getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(
    AuthService(),
  );
  getIt.registerSingleton<NavigationService>(
    NavigationService(),
  );
  getIt.registerSingleton<AlertService>(
    AlertService(),
  );
  getIt.registerSingleton<MediaService>(
    MediaService(),
  );
  getIt.registerSingleton<StorageService>(
    StorageService(),
  );
  getIt.registerSingleton<DatabaseService>(
    DatabaseService(),
  );

  getIt.registerSingleton<ChatService>(
    ChatService(),
  );
  getIt.registerSingleton<WardrobeEngineService>(
    WardrobeEngineService(),
  );
  getIt.registerSingleton<TryOnRenderer>(
    RemoteTryOnRenderer(
      fallbackRenderer: MockTryOnRenderer(),
    ),
  );
  getIt.registerSingleton<TryOnService>(
    TryOnService(),
  );
  getIt.registerSingleton<WardrobeCaptureService>(
    WardrobeCaptureService(),
  );
  getIt.registerSingleton<ClosetScannerService>(
    ClosetScannerService(),
  );
}
