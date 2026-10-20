import 'package:flutter/material.dart';
import 'ui.dart';
import 'screens/map_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';

void main() => runApp(const AlertaApp());

class AlertaApp extends StatelessWidget {
  const AlertaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Alerta Seguro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kCyan, surface: kBg),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: kBg,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
          ),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: i, children: const [
          MapScreen(), SosScreen(), SettingsScreen(), ProfileScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map, color: kCyan), label: 'Mapa'),
            NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield, color: kRed), label: 'Emergência'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: kCyan), label: 'Ajustes'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: kCyan), label: 'Perfil'),
          ],
        ),
      );
}
