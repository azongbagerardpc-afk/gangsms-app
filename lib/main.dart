import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/login_screen.dart';
import 'screens/rooms_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final pseudo = prefs.getString('pseudo');

  runApp(GangSMSApp(initialPseudo: pseudo));
}

class GangSMSApp extends StatelessWidget {
  final String? initialPseudo;
  const GangSMSApp({super.key, this.initialPseudo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GangSMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF121212),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: initialPseudo != null
          ? RoomsScreen(pseudo: initialPseudo!)
          : const LoginScreen(),
    );
  }
}
