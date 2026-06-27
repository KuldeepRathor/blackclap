import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

/// InheritedWidget that exposes the root [PersistentTabController] to any
/// descendant widget — without creating a circular import back to main.dart.
///
/// Usage in any screen:
///   AppTabController.maybeOf(context)?.jumpToTab(2);
class AppTabController extends InheritedWidget {
  final PersistentTabController controller;

  const AppTabController({
    super.key,
    required this.controller,
    required super.child,
  });

  static AppTabController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabController>();

  @override
  bool updateShouldNotify(AppTabController old) =>
      controller != old.controller;
}
