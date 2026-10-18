import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'dashboard.dart';
import 'onboarding.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  final state = await AppState.load();
  runApp(AloDiarioApp(state: state));
}

class AloDiarioApp extends StatelessWidget {
  const AloDiarioApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alô Diário',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ListenableBuilder(
        listenable: state,
        builder: (context, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.profile == null
              ? OnboardingScreen(key: const ValueKey('onb'), state: state)
              : DashboardScreen(key: const ValueKey('dash'), state: state),
        ),
      ),
    );
  }
}
