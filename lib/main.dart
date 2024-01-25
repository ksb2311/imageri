import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:imegeri/screens/home_screen.dart';
import 'package:imegeri/themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    String selectedTheme = 'Dark';
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    ThemeData getThemeData(String theme) {
      switch (theme) {
        case 'Light':
          return defaultTheme;
        case 'Dark':
          return darkTheme;
        default:
          bool isDarkMode = brightness == Brightness.dark;
          if (!isDarkMode) {
            return defaultTheme;
          } else {
            return darkTheme;
          }
      }
    }

    return MaterialApp(
      title: 'Flutter Demo',
      theme: getThemeData(selectedTheme),
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      home: const HomeScreen(),
    );
  }
}
