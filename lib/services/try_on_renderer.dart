import 'package:cinduhrella/models/try_on.dart';

abstract class TryOnRenderer {
  Future<TryOnPreview> render(TryOnRequest request);
}
