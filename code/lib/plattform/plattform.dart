import 'package:flutter/foundation.dart';

/// Names that differ between iPhone and Android (vault Umsetzung/Android
/// nachziehen.md). The browser preview shows the iPhone names.
bool get istAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// "iPhone" or "Handy".
String get handyName => istAndroid ? 'Handy' : 'iPhone';

/// "Apple Health" or "Health Connect".
String get healthName => istAndroid ? 'Health Connect' : 'Apple Health';

/// Who asks for permission: "Apple" or "Android".
String get systemName => istAndroid ? 'Android' : 'Apple';
