import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeCubit() : super(ThemeMode.dark) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? true;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool(_key, next == ThemeMode.dark);
    emit(next);
  }

  bool get isDark => state == ThemeMode.dark;
}
