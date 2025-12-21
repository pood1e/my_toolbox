import 'package:core/di.dart';
import 'package:core/i10n.dart';
import 'package:flutter/material.dart';

part 'i10n_providers.g.dart';

@riverpod
Iterable<LocalizationsDelegate<dynamic>> localizationDelegates(Ref ref) {
  final platformL10ns = ref.watch(platformLocalizationDelegatesProvider);
  final featuresL10ns = ref.watch(featuresLocalizationDelegatesProvider);
  return [...platformL10ns, ...featuresL10ns];
}

@riverpod
Iterable<LocalizationsDelegate<dynamic>> featuresLocalizationDelegates(
  Ref ref,
) {
  throw UnimplementedError('override in bootstrap');
}

@riverpod
Iterable<LocalizationsDelegate<dynamic>> platformLocalizationDelegates(
  Ref ref,
) {
  return [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
