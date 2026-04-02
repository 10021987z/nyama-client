import 'package:flutter/foundation.dart';

/// Global offline indicator updated by the API interceptor.
/// true = offline/unreachable, false = connected.
final offlineNotifier = ValueNotifier<bool>(false);
