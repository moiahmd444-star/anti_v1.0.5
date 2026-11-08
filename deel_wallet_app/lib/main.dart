import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens.dart';
import 'api.dart';
import 'data.dart';

// Orange, blanc, vert.
const brandOrange = Color(0xFFFF6B00);
const brandGreen = Color(0xFF16A34A);
const brandDark = Color(0xFF1A1A1A);

// Onboarding (3 slides) affiche seulement au tout premier lancement -- voir
// onboarding_screen.dart, qui pose ce flag une fois la derniere slide passee.
const onboardingSeenKey = 'onboarding_seen';

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandOrange,
    secondary: brandGreen,
  ),
  scaffoldBackgroundColor: Colors.white,
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brandOrange,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: brandOrange, width: 1.5),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.grey.shade100),
    ),
  ),
);

// Deconnexion automatique apres 30 min sans interaction (ecran tactile).
// shortcut: l'inactivite = aucun toucher ; une video/lecture passive de plus
// de 30 min deconnecte aussi. Horodatage persiste pour couvrir l'app tuee.
const idleLimit = Duration(minutes: 30);
const _lastActiveKey = 'last_active_ms';
final navKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> _stampActive() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool(onboardingSeenKey) ?? false;
  var token = prefs.getString('auth_token');
  final last = prefs.getInt(_lastActiveKey);
  if (token != null &&
      last != null &&
      DateTime.now().millisecondsSinceEpoch - last > idleLimit.inMilliseconds) {
    // Inactif > 30 min pendant que l'app etait fermee : session close.
    token = null;
    await prefs.remove('auth_token');
  }
  if (token != null && token.isNotEmpty) {
    Api.token = token;
    await _stampActive();
    try {
      await app.refresh();
    } on ApiException catch (e) {
      if (e.status == 401) {
        // Jeton expire (24 h) : retour a l'ecran de connexion.
        Api.token = token = null;
        await prefs.remove('auth_token');
      }
    } catch (_) {}
  }
  runApp(BaouFinanceApp(
      seenOnboarding: seenOnboarding, loggedIn: token != null && token.isNotEmpty));
}

class BaouFinanceApp extends StatefulWidget {
  const BaouFinanceApp(
      {super.key, required this.seenOnboarding, required this.loggedIn});
  final bool seenOnboarding;
  final bool loggedIn;

  @override
  State<BaouFinanceApp> createState() => _BaouFinanceAppState();
}

class _BaouFinanceAppState extends State<BaouFinanceApp>
    with WidgetsBindingObserver {
  DateTime _last = DateTime.now();
  DateTime _saved = DateTime.now();
  Timer? _timer;

  bool get _loggedIn => Api.token != null && Api.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Les timers sont suspendus en arriere-plan : on reverifie au retour.
    if (state == AppLifecycleState.resumed) _check();
  }

  void _touch() {
    final now = DateTime.now();
    _last = now;
    if (_loggedIn && now.difference(_saved) > const Duration(seconds: 30)) {
      _saved = now;
      _stampActive();
    }
  }

  void _check() {
    if (!_loggedIn || DateTime.now().difference(_last) < idleLimit) return;
    app.logout();
    navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    messengerKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Session expirée après 30 min d\'inactivité. Reconnectez-vous.')));
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _touch(),
        onPointerMove: (_) => _touch(),
        child: _app(),
      );

  Widget _app() => MaterialApp(
        title: 'BAOU',
        navigatorKey: navKey,
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: widget.loggedIn
            ? const Shell()
            : (widget.seenOnboarding
                ? const LoginScreen()
                : const OnboardingScreen()),
      );
}

/// Logo importe depuis assets/logo.jpg. Bascule sur le wordmark texte si le
/// fichier venait a manquer — rien ne casse.
class Logo extends StatelessWidget {
  const Logo({super.key, this.height = 72});
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/logo.jpg',
          height: height,
          errorBuilder: (_, __, ___) => Text(
            'BAOU Finance',
            style: TextStyle(
                fontSize: height * .3,
                fontWeight: FontWeight.w700,
                color: brandDark),
          ),
        ),
      );
}
