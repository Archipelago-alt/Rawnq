import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// Router instance, exposed as a provider so tests can supply their own.
final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class RawnqApp extends ConsumerWidget {
  const RawnqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RAWNQ',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildRawnqTheme(),
      // Arabic is the store's only language, so the app is Arabic-only and
      // laid out right-to-left throughout.
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Cap text scaling so very large system font settings cannot break
        // the product grid, while still honouring the user's preference.
        final scaler = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
